#!/bin/bash
set -e

# This is just to separate script output from git filter-branch output
echo ""

_SDK_LIST_PATH=$1
if [[ -z $_SDK_LIST_PATH || ! -f $_SDK_LIST_PATH ]]; then
	echo "Please provide path to file which contains list of SDK files/dirs."
	exit 1
fi

COUNT_SDK_FILES=$(cat $_SDK_LIST_PATH | wc -l | tr -d ' ')
echo "Exclusion list of ${COUNT_SDK_FILES} paths provided."

ALL_FILES=$(git ls-files)
COUNT_ALL_FILES=$(echo "$ALL_FILES" | wc -l | tr -d ' ')
echo "Found total of $COUNT_ALL_FILES paths tracked by git."

echo "Filtering (nonSDK) paths for removal via provided exclusion list..."
TO_REMOVE_LIST=$(echo "$ALL_FILES" | grep -Fxvf $_SDK_LIST_PATH)
COUNT_TO_REMOVE_LIST=$(echo "$TO_REMOVE_LIST" | wc -l | tr -d ' ')
echo "Initially filtered $COUNT_TO_REMOVE_LIST paths for removal."

# Reduce the list by considering certain parent dirs as non SDK
_EXCLUDE_DIRS=$2
COUNT_EXCLUDE_DIRS=$(echo "$_EXCLUDE_DIRS" | wc -l | tr -d ' ')
echo "Reducing list using $COUNT_EXCLUDE_DIRS parent dirs..."
while read -r DIR; do
	TO_REMOVE_LIST=$(echo "$TO_REMOVE_LIST" | grep -v "^${DIR}")
	TO_REMOVE_LIST="${TO_REMOVE_LIST}
${DIR}"
done <<< "$_EXCLUDE_DIRS"

COUNT_TO_REMOVE_LIST=$(echo "$TO_REMOVE_LIST" | wc -l | tr -d ' ')
echo "Removing ${COUNT_TO_REMOVE_LIST} paths..."

while read -r file; do
	git rm -rf --cached --ignore-unmatch ${file} >/dev/null;
done <<< "$TO_REMOVE_LIST"

echo "Files removed."
