#!/bin/bash

# TODO: Check go
# TODO: Check jq
# TODO: Check version of grep to make sure it's GNU 3.3+

SCRIPT_DIR=$(realpath $(dirname $0))

echo "Moving all packages under /sdk"
DIRS_TO_MOVE=$(ls)
mkdir -p sdk/internal
echo "$DIRS_TO_MOVE" | xargs -I{} git mv -v {} sdk/{}

# Change import paths
echo "Changing import paths from terraform to terraform-plugin-sdk ..."
find . -name '*.go' | xargs -I{} sed -i 's/github.com\/hashicorp\/terraform\([\/"]\)/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\1/' {}

echo "Moving internal packages up ..."
# Flatten sdk/internal/* into sdk/* to avoid nested internal packages & breaking import trees
INTERNAL_FOLDERS=$(go list -json ./... | jq -r .Dir | sed -e "s;^$SCRIPT_DIR\/sdk\/;;" | grep -E '^internal\/' | sed -e 's/^internal\///')
cd ./sdk
echo "$INTERNAL_FOLDERS" | xargs -I{} git mv -v ./internal/{} ./{}
rm -rf ./internal/internal
echo "$INTERNAL_FOLDERS" | sed 's/\//\\\\\//g' | xargs -I{} sh -c "find . -name '*.go' | xargs -I@ sed -i 's/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/internal\/{}/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/{}/' @"
cd ..
echo "Internal packages moved."

echo "(re)initializing go modules ..."
go mod init github.com/hashicorp/terraform-plugin-sdk
go get ./...
go mod tidy
echo "Go modules initialized."
