#! /bin/bash

BASE_PATH=$(pwd)

# Destroy terraform infra
cd $BASE_PATH/iac

terraform destroy -auto-approve

rm -rf .terraform*
rm -rf *.tfstate
rm -rf *.tfstate.*
rm -rf *.lock.hcl

cd $BASE_PATH

# Cleaning workspaces
rm -rf **/*dist/
rm -rf **/*node_modules/