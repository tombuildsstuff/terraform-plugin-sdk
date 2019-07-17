#!/bin/bash
set -e

FILEPATH=$1
EXCLUDE_DIRS=$2

while read -r DIR; do
  if [[ "$FILEPATH" == ${DIR}* ]]; then
    exit 0
  fi
done <<< "$EXCLUDE_DIRS"

echo $FILEPATH
