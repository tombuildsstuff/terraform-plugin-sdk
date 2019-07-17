#!/bin/bash
set -e

SCRIPT_DIR=$(realpath $(dirname $0))

# This is just to separate script output from git filter-branch output
echo ""

_SDK_DIR_LIST_PATH=$1
if [[ -z $_SDK_DIR_LIST_PATH || ! -f $_SDK_DIR_LIST_PATH ]]; then
	echo "Please provide path to file which contains list of SDK files/dirs."
	exit 1
fi

COUNT_SDK_FILES=$(cat $_SDK_DIR_LIST_PATH | wc -l | tr -d ' ')
echo "List of ${COUNT_SDK_FILES} SDK dirs provided."

ALL_PATHS=$(git ls-files)
COUNT_ALL_PATHS=$(echo "$ALL_PATHS" | wc -l | tr -d ' ')
ALL_PATHS_PATH=$(mktemp); echo "$ALL_PATHS" > $ALL_PATHS_PATH
echo "All ${COUNT_ALL_PATHS} paths listed in ${ALL_PATHS_PATH}"

# Reduce the list by considering certain parent dirs as non SDK
EXCLUDE_DIRS=$2
echo "Excluding paths which are in blacklisted directories ..."
ALL_PATHS=$(echo "$ALL_PATHS" | xargs -I{} $SCRIPT_DIR/exclude-dirs.sh {} "$EXCLUDE_DIRS")
COUNT_ALL_PATHS=$(echo "$ALL_PATHS" | wc -l | tr -d ' ')
ALL_PATHS_PATH=$(mktemp); echo "$ALL_PATHS" > $ALL_PATHS_PATH
echo "All ${COUNT_ALL_PATHS} filtered paths listed in ${ALL_PATHS_PATH}"

echo "Converting paths to dirs ..."
ALL_DIRS=$(echo "$ALL_PATHS" | xargs -I{} $SCRIPT_DIR/dirname.sh {} | sort | uniq)
COUNT_ALL_DIRS=$(echo "$ALL_DIRS" | wc -l | tr -d ' ')
ALL_DIRS_PATH=$(mktemp); echo "$ALL_DIRS" > $ALL_DIRS_PATH
echo "All ${COUNT_ALL_DIRS} dirs listed in ${ALL_DIRS_PATH}"

echo "Filtering (nonSDK) dirs for removal via provided SDK dirs list..."
TO_REMOVE_LIST=$(echo "$ALL_DIRS" | grep -Fxvf $_SDK_DIR_LIST_PATH)
TO_REMOVE_LIST="${TO_REMOVE_LIST}
${EXCLUDE_DIRS}"
COUNT_TO_REMOVE_LIST=$(echo "$TO_REMOVE_LIST" | wc -l | tr -d ' ')
TO_REMOVE_LIST_PATH=$(mktemp); echo "$TO_REMOVE_LIST" > $TO_REMOVE_LIST_PATH
echo "List of ${COUNT_TO_REMOVE_LIST} paths for removal listed in ${TO_REMOVE_LIST_PATH}"

echo "Removing paths from git ..."
while read -r file; do
	git rm -rf --cached --ignore-unmatch ${file} >/dev/null;
done <<< "$TO_REMOVE_LIST"
echo "Paths removed."
