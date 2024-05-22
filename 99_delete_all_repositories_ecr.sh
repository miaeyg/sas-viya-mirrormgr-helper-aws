#!/bin/bash

source 00_vars.sh


# loop on all ECR repos and delete them
for repName in $(aws ecr describe-repositories $AWS_CLI_PARMS --no-cli-pager  | jq -r '.repositories[].repositoryName')
do
    echo "Deleting repo: $repName"
    aws ecr batch-delete-image --repository-name $repName $AWS_CLI_PARMS --image-ids "$(aws ecr list-images $AWS_CLI_PARMS --repository-name $repName --query 'imageIds[*]' --output json)"
    aws ecr delete-repository --repository-name $repName $AWS_CLI_PARMS
done
