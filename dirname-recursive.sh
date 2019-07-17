#!/bin/bash
set -e

FILEPATH=$1

DIRNAME=$(dirname $FILEPATH)
if [[ "$DIRNAME" == "." ]]; then
  echo $1
  exit 0
fi

echo $DIRNAME

$0 $DIRNAME
