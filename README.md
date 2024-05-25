# sas-viya-mirrormgr-helper-aws

![Static Badge](https://img.shields.io/badge/license-MIT-blue)![GitHub last commit](https://img.shields.io/github/last-commit/miaeyg/sas-viya-mirrormgr-helper-aws)


This project contains scripts which assist in downloading and uploading SAS Viya4 docker images to AWS private ECR the using SAS Mirror Manager utility and also in cleaning up the ECR repositories.
The scripts maintain log files for each action performed in the Logs directory.

### Prerequisites:
1. Linux
2. AWS CLI installed and authenticated to AWS
3. SAS Mirror Manager 


### Usage:

1. Download SAS mirrormgr either from https://support.sas.com/en/documentation/install-center/viya/deployment-tools/4/mirror-manager.html or via commands:
```
wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
tar -xvzf mirrormgr-linux.tgz
```

2. Run `chmod u+x *.sh`
3. Edit `00_vars.sh`
4. Run `01_sas_to_ecr.sh [estimate|download|verify|upload|create_ecr_repos|upload_to_ecr]`

   you can split upload to two steps: create_ecr_repos which creates ECR repos / upload_to_ecr which uploads SAS docker images to ECR repos

5. Run `99_delete_sas_repositories_ecr.sh` to cleanup ECR by deleting all SAS Mirror Manager uploaded ECR repos