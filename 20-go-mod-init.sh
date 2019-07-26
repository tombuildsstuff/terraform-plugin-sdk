#!/bin/bash

# TODO: Check go
# TODO: Check jq
# TODO: Check version of grep to make sure it's GNU 3.3+

echo "Moving all packages under /sdk"
DIRS_TO_MOVE=$(ls)
mkdir -p sdk/internal
echo "$DIRS_TO_MOVE" | xargs -I{} git mv -v {} sdk/{}

# Change import paths
echo "Changing import paths from terraform to terraform-plugin-sdk ..."
find . -name '*.go' | xargs -I{} sed -i 's/github.com\/hashicorp\/terraform\([\/"]\)/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\1/' {}

echo "Moving internal packages up ..."
# Flatten sdk/internal/* into sdk/* to avoid nested internal packages & breaking import trees
INTERNAL_FOLDERS=$(go list -json ./... | jq -r .Dir | sed -e "s;^$PWD\/sdk\/;;" | grep -E '^internal\/' | sed -e 's/^internal\///')
cd ./sdk
COUNT_FOLDERS=$(echo "$INTERNAL_FOLDERS" | wc -l | tr -d ' ')
echo "Found ${COUNT_FOLDERS} internal folders for moving."
echo "$INTERNAL_FOLDERS" | xargs -I{} git mv -v ./internal/{} ./{}
rm -rf ./internal/internal
# Update import paths for internal packages
echo "$INTERNAL_FOLDERS" | sed 's/\//\\\\\//g' | xargs -I{} sh -c "find . -name '*.go' | xargs -I@ sed -i 's/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/internal\/{}/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\/{}/' @"
cd ..
echo "Internal packages moved."

echo "(re)initializing go modules ..."
go mod init github.com/hashicorp/terraform-plugin-sdk
go get ./...
go mod tidy
echo "Go modules initialized."
