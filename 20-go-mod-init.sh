#!/bin/bash

# TODO: Check go
# TODO: Check version of grep to make sure it's GNU 3.3+

# Change import paths
echo "Changing import paths from terraform to terraform-plugin-sdk ..."
find . -name '*.go' | xargs -I{} sed -i 's/github.com\/hashicorp\/terraform\([\/"]\)/github.com\/hashicorp\/terraform-plugin-sdk\1/' {}

echo "(re)initializing go modules ..."
go mod init github.com/hashicorp/terraform-plugin-sdk
go get ./...
go mod tidy
go mod vendor
echo "Go modules initialized."

git add -A && git commit -m "Initialize go modules"
