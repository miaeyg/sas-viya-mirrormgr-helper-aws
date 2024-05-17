#!/bin/bash

source 00_vars.sh

# https://documentation.sas.com/doc/en/itopscdc/v_045/dplyml0phy0dkr/p0lexw9inr33ofn1tbo69twarhlx.htm

# download SAS mirrormgr from https://support.sas.com/en/documentation/install-center/viya/deployment-tools/4/mirror-manager.html
# > wget https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz
# > tar -xvzf mirrormgr-linux.tgz
#
# download AWS CLI and configure it "aws configure" or "aws configure sso" and get the profile name
# create folder like so:
#   /sas/<order>/stable-2024.04 or /sas/<order>/lts-2023.10

#
# Usage:
#
# 01_sas_to_ecr.sh estimate/download/upload
#
# typically one would execute: 
#   "estimate" and make sure there is enough disk space to store repo
#   "download" to download and verify sas_repo
#   "upload" but before that login to aws 
#
#   "upload" can be split to "upload_step1" and "upload_step2"
#   "upload_step1" creates the repositories in ECR should only be run once
#   "upload_step2" uploads the SAS images to ECR can be run multiple times if aborted/stopped/failed
#

if [[ ! -f "${ASSETSPATH}/${CERTSFILE}" ]]; then
    echo "CERTSFILE does not exist."
    exit 1
fi


if [[ ! -f "${ASSETSPATH}/${ASSETSFILE}" ]]; then
    echo "ASSETSFILE does not exist."
    exit 1
fi

# Parse SAS deployment assets filename to pick up cadence + version + release for download usage
arrASSETSFILE=(${ASSETSFILE//_/ })
export CADENCE=${arrASSETSFILE[3]}
export VERSION=${arrASSETSFILE[4]}
export RELEASE=${arrASSETSFILE[5]}

# reusable functions
estimate() {
    echo "Size estimate for SAS repo ${MIRRORPATH} (can take a while)."
    ${MIRRORMGRPATH}/mirrormgr list remote repos size --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE}
}

download() {
    echo "Downloading SAS repo to ${MIRRORPATH}. Writing to log file mm_download.log"
    #${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --deployment-assets ${ASSETSPATH}/${ASSETSFILE} --workers 10 --log-file mm_download.log
    ${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file mm_download.log
}

verify() {
    echo "Verifying repo ${MIRRORPATH}. Writing to log file mm_verify.log"
    ${MIRRORMGRPATH}/mirrormgr verify registry --path ${MIRRORPATH} --log-file mm_verify.log
    echo "==================="
    echo "Downloaded release verification: ls -l ${MIRRORPATH}/lod/${CADENCE}/${VERSION}"    
    ls -l ${MIRRORPATH}/lod/${CADENCE}/${VERSION}
    echo "==================="
}

upload_step1() {
    echo "Uploading repo step1 creating ECR repos."
    for repo in $($MIRRORMGRPATH/mirrormgr list target docker repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${NS}) ; do
        echo "Working on SAS repo: $repo"
        aws ecr describe-repositories $AWS_CLI_PARMS --repository-names $repo || aws ecr create-repository $AWS_CLI_PARMS --repository-name $repo
    done
}

upload_step2() {
    echo "Uploading repo step2 uploading images. Writing to log file mm_upload.log"
    ${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${ECRURL}/${NS} --username 'AWS' --password $(aws ecr get-login-password $AWS_CLI_PARMS) --push-only --workers ${WORKERS} --log-file mm_upload.log
}

# act upon user passed argument
case $1 in
  "estimate")
    estimate
    ;;
  "download")
    download
    verify
    ;;
  "verify")
    verify 
    ;;
  "upload")
    upload_step1
    upload_step2
    ;;
  "upload_step1")
    upload_step1
    ;;
  "upload_step2")
    upload_step2
    ;;
  *)
    echo "Usage: 01_sas_to_ecr.sh [estimate|download|verify|upload|upload_step1|upload_step2]"    
    ;;
esac