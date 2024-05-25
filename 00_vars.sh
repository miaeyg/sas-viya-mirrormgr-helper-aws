#!/bin/bash

# URL of Private ECR in AWS
export ECRURL=https://<accountid>.dkr.ecr.<region>.amazonaws.com

# path to directory containing the SAS assets files
export ASSETSPATH=<path-to-folder-containing-SAS-certs-and-assets-files>

# SAS Assets file name
export ASSETSFILE=SASViyaV4_<order>_0_<order-info>.tgz

# SAS Certs file name
export CERTSFILE=SASViyaV4_<order>_certs.zip

# path to directory where downloaded SAS Docker Images will be kept
export MIRRORPATH=<path-to-directory-to-contain-downloaded-images>

# path to directory where SAS Mirror Manager is installed
export MIRRORMGRPATH=<path-to-folder-containing-SAS-mirrormgr-executable>

# name of namespace in ECR underwhich the images will be uploaded for example "viya/..."
export NS=viya

# number of workers used by SAS Mirror Manager used for download/upload
export WORKERS=10

# additional AWS CLI options you want the script to use
export AWS_CLI_PARMS=

# AWS_CLI_PARMS usage examples
# AWS_CLI_PARMS=--profile default
# AWS_CLI_PARMS=--region il-central-1
