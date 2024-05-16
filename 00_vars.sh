#!/bin/bash

export ECRURL=https://<accountid>.dkr.ecr.<region>.amazonaws.com
export ASSETSPATH=<path-to-SAS-certs-and-assets-files>
export ASSETSFILE=SASViyaV4_<order>_0_<order-info>.tgz
export CERTSFILE=SASViyaV4_<order>_certs.zip
export MIRRORPATH=<path-to-downloaded-images>
export MIRRORMGRPATH=<path-to-folder-containing-SAS-mirrormgr-executable>
export NS=viya
export AWS_CLI_PARMS=

# AWS_CLI_PARMS usage examples
# AWS_CLI_PARMS=--profile default
# AWS_CLI_PARMS=--region il-central-1
