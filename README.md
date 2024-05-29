# sas-viya-mirrormgr-helper-aws

![Static Badge](https://img.shields.io/badge/license-MIT-blue) ![GitHub Tag](https://img.shields.io/github/v/tag/miaeyg/sas-viya-mirrormgr-helper-aws?color=green)



This project contains scripts which assist in downloading and uploading SAS Viya4 docker images to AWS private ECR the using SAS Mirror Manager utility and also in cleaning up the ECR repositories.
The scripts maintain log files for each action performed in the Logs directory.

### Prerequisites:
1. Linux
2. AWS CLI
3. SAS Mirror Manager 


### Installation:

1. Clone this project or download the latest tagged version
2. Obtain the SAS Viya assets for your order from [my.sas.com](https://my.sas.com) or using [viya4-orders-cli](https://github.com/sassoftware/viya4-orders-cli) 
2. Download [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
3. Download SAS Mirror Manager from [SAS Mirror Manager](https://support.sas.com/en/documentation/install-center/viya/deployment-tools/4/mirror-manager.html) or use the following commands:
```
wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
tar -xvzf mirrormgr-linux.tgz
```
### Usage:

1. Authenticate to AWS using AWS CLI
2. Run `chmod u+x *.sh`
3. Edit [00_vars.sh](00_vars.sh)
4. Run `01_sas_to_ecr.sh [estimate|download|verify|upload|create_ecr_repos|upload_to_ecr]`

   estimate = estimate the disk size for downloading SAS docker images  
   download = downloads and verifies the downloades images  
   verify = verifies the downloaded images  
   upload = creates ECR repos and uploads SAS images to those repos  
   create_ecr_repos = creates ECR repos  
   upload_to_ecr = uploads SAS images to ECR repos  
   
5. Run `99_delete_sas_repositories_ecr.sh` to cleanup ECR by deleting all SAS Mirror Manager uploaded ECR repos