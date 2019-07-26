#!/bin/bash

# TODO: Check go
# TODO: Check jq
# TODO: Check version of grep to make sure it's GNU 3.3+

echo "Moving all packages under /sdk"
DIRS_TO_MOVE=$(ls)
mkdir sdk
echo "$DIRS_TO_MOVE" | xargs -I{} git mv -v {} sdk/{}

# Change import paths
echo "Changing import paths from terraform to terraform-plugin-sdk ..."
find . -name '*.go' | xargs -I{} sed -i 's/github.com\/hashicorp\/terraform\([\/"]\)/github.com\/hashicorp\/terraform-plugin-sdk\/sdk\1/' {}

git add -A && git commit -m "Move packages under /sdk"

echo "(re)initializing go modules ..."
go mod init github.com/hashicorp/terraform-plugin-sdk
go get ./...
go mod tidy
echo "Go modules initialized."

git add -A && git commit -m "Initialize go modules"
