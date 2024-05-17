# sas-viya-mirrormgr-helper-aws
This project contains a script which assists in downloading and uploading SAS Viya V4 docker images to AWS private ECR

Usage:

download SAS mirrormgr from https://support.sas.com/en/documentation/install-center/viya/deployment-tools/4/mirror-manager.html
```
wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
tar -xvzf mirrormgr-linux.tgz
```

1. chmod u+x *
2. Edit 00_vars.sh
3. Run 01_sas_to_ecr.sh [estimate|download|verify|upload|upload_step1|upload_step2]

   you can split upload to two steps: upload_step1 which creates ECR repos / upload_step2 which uploads SAS docker images to ECR repos

4. Run 02_delete_all_repositories_ecr.sh to cleanup ECR by deleting all ECR repos

Prerequisites:
1. Linux
2. AWS CLI
3. SAS Mirror Manager
