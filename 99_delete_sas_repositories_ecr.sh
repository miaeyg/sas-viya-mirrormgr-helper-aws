    #!/bin/bash

    source 00_vars.sh

    read -p "Are you sure you want to delete all ECR repos starting with '$NS/'? (y/n) " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
    then
        # loop on all ECR repos whos name starts with the value of the NS variable and delete them
        for repName in $(aws ecr describe-repositories $AWS_CLI_PARMS --no-cli-pager --query "repositories[?starts_with(repositoryName, '${NS}/')].repositoryName" --output text)
        do
            echo "Deleting repo: $repName"
            aws ecr batch-delete-image --repository-name $repName $AWS_CLI_PARMS --image-ids "$(aws ecr list-images $AWS_CLI_PARMS --repository-name $repName --query 'imageIds[*]' --output json)"
            aws ecr delete-repository --repository-name $repName $AWS_CLI_PARMS
        done
    fi