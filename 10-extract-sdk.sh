#!/bin/bash
set -e

# TODO: Check go
# TODO: Check jq
# TODO: Check ifne (moreutils)
# TODO: Check version of grep to make sure it's GNU 3.3+

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

# Turn dirs into patterns
SDK_PATTERNS=$(echo "$ALL_PKGS" | xargs -I{} echo '^{}/(testdata/.*|test-fixtures/.*|[^/]*)$')
SDK_PATTERNS_PATH=$(mktemp); echo "$SDK_PATTERNS" > $SDK_PATTERNS_PATH
echo "SDK patterns listed in ${SDK_PATTERNS_PATH}"

# Remove non-SDK files
GIT_FILTER_LOG_PATH=$(mktemp)
echo "Filtering commits, logging to ${GIT_FILTER_LOG_PATH}"
git filter-branch --prune-empty --index-filter "git ls-files | grep -Evf $SDK_PATTERNS_PATH | cut -d / -f 1-2 | uniq | ifne xargs -n1 git rm --quiet -rf" HEAD > $GIT_FILTER_LOG_PATH
