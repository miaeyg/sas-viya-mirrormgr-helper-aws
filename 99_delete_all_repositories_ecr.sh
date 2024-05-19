#!/bin/bash

#
# This script can be executed several times if for some unknown reason it does not delete all in 1 go
#
# PREREQUISITES:
# 1. AWS CLI
# 2. jq
#

AWS_CLI_PARMS=

## examples of additional parameters passed in to AWS CLI
# AWS_CLI_PARMS=--profile default
# AWS_CLI_PARMS=--region il-central-1

# loop on all ECR repos and delete them
for repName in $(aws ecr describe-repositories $AWS_CLI_PARMS --no-cli-pager  | jq -r '.repositories[].repositoryName')
do
    echo "Deleting repo: $repName"
    aws ecr batch-delete-image --repository-name $repName $AWS_CLI_PARMS --image-ids "$(aws ecr list-images $AWS_CLI_PARMS --repository-name $repName --query 'imageIds[*]' --output json)"
    aws ecr delete-repository --repository-name $repName $AWS_CLI_PARMS
done
