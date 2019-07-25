#!/bin/bash
set -e

# TODO: Check go
# TODO: Check jq
# TODO: Check version of grep to make sure it's GNU 3.3+

SCRIPT_DIR=$(realpath $(dirname $0))

SDK_FOLDERS="helper/acctest
helper/customdiff
helper/encryption
helper/hashcode
helper/logging
helper/mutexkv
helper/pathorcontents
helper/resource
helper/schema
helper/structure
helper/validation
httpclient
plugin
terraform
"

echo "Finding imports ..."
IMPORTS=$(echo "$SDK_FOLDERS" | xargs -I{} go list -json ./{} | jq -r ".ImportPath" | sort | uniq | sed -e 's/^github.com\/hashicorp\/terraform\///')
echo "Finding build dependencies ..."
DEPS=$(echo "$SDK_FOLDERS" | xargs -I{} go list -json ./{} | jq -r ". | select((.Deps | length) > 0) | (.Deps[] + \"\n\" + .ImportPath) | select(startswith(\"github.com/hashicorp/terraform/\"))" | sort | uniq | sed -e 's/^github.com\/hashicorp\/terraform\///')

echo "Finding test dependencies ..."
TEST_IMPORTS=$(echo "$DEPS" | xargs -I{} go list -json ./{} | jq -r ". | select((.TestImports | length) > 0) | .TestImports[] | select(startswith(\"github.com/hashicorp/terraform/\"))" | sort | uniq | sed -e 's/^github.com\/hashicorp\/terraform\///')
TEST_DEPS=$(echo "$TEST_IMPORTS" | xargs -I{} go list -json ./{} | jq -r ". | select((.Deps | length) > 0) | (.Deps[] + \"\n\" + .ImportPath) | select(startswith(\"github.com/hashicorp/terraform/\"))" | sort | uniq | sed -e 's/^github.com\/hashicorp\/terraform\///')

echo "All dependencies found."

# Find all SDK related files
ALL_PKGS=$(printf "${IMPORTS}\n${DEPS}\n${TEST_IMPORTS}\n${TEST_DEPS}" | sort | uniq)
ALL_PKGS_LIST_PATH=$(mktemp); echo "$ALL_PKGS" > $ALL_PKGS_LIST_PATH
echo "All packages listed in ${ALL_PKGS_LIST_PATH}"
COUNT_PKG=$(echo "$ALL_PKGS" | wc -l | tr -d ' ')
echo "Finding files of ${COUNT_PKG} packages ..."

SDK_DIRS=$(echo "$ALL_PKGS" | xargs -I_  find . -path ./_/* \( -path './_/testdata*' -or -prune \) | xargs -I{} realpath --relative-to ./ {} | xargs -I{} $SCRIPT_DIR/dirname-recursive.sh {} | sort | uniq)
SDK_DIRS_PATH=$(mktemp); echo "$SDK_DIRS" > $SDK_DIRS_PATH
echo "SDK dirs listed in ${SDK_DIRS_PATH}"

# Turn dirs into patterns
SDK_PATTERNS=$(echo "$SDK_DIRS" | xargs -I{} echo '^{}/(testdata/.*|[^/]*)$')
SDK_PATTERNS_PATH=$(mktemp); echo "$SDK_PATTERNS" > $SDK_PATTERNS_PATH
echo "SDK patterns listed in ${SDK_PATTERNS_PATH}"

# Remove non-SDK files
GIT_FILTER_LOG_PATH=$(mktemp)
echo "Filtering commits, logging to ${GIT_FILTER_LOG_PATH}"
git filter-branch --prune-empty --index-filter "git ls-files | grep -Evf $SDK_PATTERNS_PATH | cut -d / -f 1-2 | uniq | xargs -n1 git rm -rf" HEAD > $GIT_FILTER_LOG_PATH

echo "Moving all packages under /sdk"
DIRS_TO_MOVE=$(ls)
mkdir -p sdk/internal
echo "$DIRS_TO_MOVE" | xargs -I{} git mv {} sdk/{}

# Change import paths
echo "Changing import paths from terraform to terraform-plugin-sdk ..."
find . -name '*.go' | xargs -I{} sed -i 's/github.com\/hashicorp\/terraform\([\/"]\)/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\1/' {}

echo "(re)initializing go modules ..."
go mod init
go get ./...
go mod tidy
echo "Go modules initialized."

echo "Moving internal packages up ..."
# Flatten sdk/internal/* into sdk/* to avoid nested internal packages & breaking import trees
INTERNAL_FOLDERS=$(go list -json ./... | jq -r .ImportPath | sed -e 's/^github.com\/hashicorp\/terraform-plugin-sdk\/sdk\///' | grep -E '^internal\/' | sed -e 's/^internal\///')
cd ./sdk
echo "$INTERNAL_FOLDERS" | xargs -I{} mv ./internal/{} ./{}
rm -rf ./internal
echo "$INTERNAL_FOLDERS" | sed 's/\//\\\\\//g' | xargs -I{} sh -c "find . -name '*.go' | xargs -I@ sed -i 's/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/internal\/{}/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/{}/' @"
echo "Internal packages moved."

echo "Finding non-SDK packages & folders ..."
# Internalize non-SDK packages
SDK_PKGS_LIST_PATH=$(mktemp)
# Find all parent folders first
PARENT_FOLDERS="$SDK_FOLDERS"
while [[ $(echo -n "$PARENT_FOLDERS" | wc -l) -gt 0 ]]; do
	PARENT_FOLDERS=$(echo "$PARENT_FOLDERS" | xargs -I{} dirname {} | grep -xFv '.' | sort | uniq)
	echo "$PARENT_FOLDERS" | xargs -I{} echo ./{} > $SDK_PKGS_LIST_PATH
done

echo "$SDK_FOLDERS" | xargs -I{} echo ./{} >> $SDK_PKGS_LIST_PATH

echo "SDK packages stored in $SDK_PKGS_LIST_PATH"

SDK_FOLDERS_PATTERNS_PATH=$(mktemp)
cat $SDK_PKGS_LIST_PATH | xargs -I{} sh -c "echo ^{}\$; echo ^{}/testdata" > $SDK_FOLDERS_PATTERNS_PATH
NONSDK_FOLDERS=$(find . -type d -and \( ! -path './.git*' \) | grep -xFv '.' | grep -v -f $SDK_FOLDERS_PATTERNS_PATH)
NONSDK_GO_PKGS=$(go list -json ./... | jq -r .ImportPath | sed -e 's/^github.com\/hashicorp\/terraform-plugin-sdk\/sdk/\./' | grep -xFv -f $SDK_PKGS_LIST_PATH | sed -e 's/^\.\///')

NONSDK_GO_PKGS_PATH=$(mktemp)
echo "$NONSDK_GO_PKGS" > $NONSDK_GO_PKGS_PATH
echo "NonSDK packages stored in $NONSDK_GO_PKGS_PATH"

NONSDK_FOLDERS_PATH=$(mktemp)
echo "$NONSDK_FOLDERS" > $NONSDK_FOLDERS_PATH
echo "NonSDK folders stored in $NONSDK_FOLDERS_PATH"

# Move all non-SDK folders
echo "Moving non-SDK folders under internal ..."
echo "$NONSDK_FOLDERS" | xargs -I{} sh -c 'mkdir -p $(dirname ./internal/{}); [ -d {} ] && mv -v {} ./internal/{} || true'
echo "Non-SDK folders moved."

# Fix imports in newly moved non-SDK packages
COUNT_NONSDK_GO_PKGS=$(echo "$NONSDK_GO_PKGS" | wc -l | tr -d ' ')
echo "Updating $COUNT_NONSDK_GO_PKGS import paths for moved files ..."
echo "$NONSDK_GO_PKGS" | sed 's/\//\\\\\//g' | xargs -I{} sh -c "find . -name '*.go' | xargs -I@ sed -i 's/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/{}\([\/\"]\)/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/internal\/{}\1/' @"
echo "Import paths updated."
