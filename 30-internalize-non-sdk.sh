#!/bin/bash

# TODO: Check go
# TODO: Check jq
# TODO: Check version of grep to make sure it's GNU 3.3+

echo "Moving internal packages up ..."
# Flatten sdk/internal/* into sdk/* to avoid nested internal packages & breaking import trees
INTERNAL_FOLDERS=$(go list -json ./... | jq -r .Dir | sed -e "s;^$PWD\/sdk\/;;" | grep -E '^internal\/' | sed -e 's/^internal\///')
cd ./sdk
COUNT_FOLDERS=$(echo "$INTERNAL_FOLDERS" | wc -l | tr -d ' ')
echo "Found ${COUNT_FOLDERS} internal folders for moving."
echo "$INTERNAL_FOLDERS" | xargs -I{} git mv -v ./internal/{} ./{}
rm -rf ./internal
# Update import paths for internal packages
echo "$INTERNAL_FOLDERS" | sed 's/\//\\\\\//g' | xargs -I{} sh -c "find . -name '*.go' | xargs -I@ sed -i 's/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/internal\/{}/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/{}/' @"
echo "Internal packages moved."

# TODO: Pass this as a variable + check
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
NONSDK_GO_PKGS=$(go list -json ./... | jq -r .ImportPath | sed -e 's/^github.com\/hashicorp\/terraform-plugin-sdk\/sdk/\./' | grep -v -f $SDK_FOLDERS_PATTERNS_PATH | sed -e 's/^\.\///')

NONSDK_GO_PKGS_PATH=$(mktemp)
echo "$NONSDK_GO_PKGS" > $NONSDK_GO_PKGS_PATH
echo "NonSDK packages stored in $NONSDK_GO_PKGS_PATH"

NONSDK_FOLDERS_PATH=$(mktemp)
echo "$NONSDK_FOLDERS" > $NONSDK_FOLDERS_PATH
echo "NonSDK folders stored in $NONSDK_FOLDERS_PATH"

# Move all non-SDK folders
echo "Moving non-SDK folders under internal ..."
mkdir ./internal
# Because NONSDK_FOLDERS contains nested folders and parents
# can be moved before we get to children, we just ignore
# the ones that are moved already + mv doesn't create intermediate dirs
echo "$NONSDK_FOLDERS" | xargs -I{} sh -c '[ -d {} ] && mkdir -p $(dirname ./internal/{}) && mv -v {} ./internal/{}'
echo "Non-SDK folders moved."

# Fix imports in newly moved non-SDK packages
COUNT_NONSDK_GO_PKGS=$(echo "$NONSDK_GO_PKGS" | wc -l | tr -d ' ')
echo "Updating $COUNT_NONSDK_GO_PKGS import paths for moved files ..."
echo "$NONSDK_GO_PKGS" | sed 's/\//\\\\\//g' | xargs -I{} sh -c "find . -name '*.go' | xargs -I@ sed -i 's/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/{}\([\/\"]\)/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/internal\/{}\1/' @"
echo "Import paths updated."

git add -A && git commit -m "Hide non-SDK packages under sdk/internal"
