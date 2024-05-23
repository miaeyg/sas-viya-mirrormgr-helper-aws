# sas-viya-mirrormgr-helper-aws

This project contains scripts which assist in downloading and uploading SAS Viya V4 docker images to AWS private ECR using SAS Mirror Manager and also in cleaning up the ECR repositories.

Prerequisites:
1. Linux
2. AWS CLI
3. SAS Mirror Manager


Usage:

1. download SAS mirrormgr either from https://support.sas.com/en/documentation/install-center/viya/deployment-tools/4/mirror-manager.html or like this:
```
wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
tar -xvzf mirrormgr-linux.tgz
```

2. chmod u+x *.sh
3. Edit 00_vars.sh
4. Run 01_sas_to_ecr.sh [estimate|download|verify|upload|upload_step1|upload_step2]

   you can split upload to two steps: upload_step1 which creates ECR repos / upload_step2 which uploads SAS docker images to ECR repos

5. Run 99_delete_sas_repositories_ecr.sh to cleanup ECR by deleting all SAS Mirror Manager uploaded ECR repos


### This project is licensed under the terms of the MIT license.