#!/bin/bash

source 00_vars.sh

# verify required files exist before proceeding
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
export DT=$(date "+%Y%m%d_%H%M%S")

echo "==============================================="
echo "CADENCE=${CADENCE}"
echo "VERSION=${VERSION}"
echo "RELEASE=${RELEASE}"

# estimate size of to be downloaded mirror
estimate() {
    echo "==============================================="
    echo "Mirror Manager Helper: Size estimate for SAS repo ${MIRRORPATH} (can take a while)."
    ${MIRRORMGRPATH}/mirrormgr list remote repos size --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE}
}

# download SAS mirror
download() {
    echo "==============================================="
    echo "Mirror Manager Helper: Downloading SAS repo to ${MIRRORPATH}. Writing to log file mmh_download_${DT}.log"
    #${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --deployment-assets ${ASSETSPATH}/${ASSETSFILE} --workers ${WORKERS} --log-file mmh_download.log
    ${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file mmh_download_${DT}.log
}

# verify downloaded mirror and output downloaded release info 
verify() {
    echo "==============================================="
    echo "Mirror Manager Helper: Verifying repo ${MIRRORPATH}. Writing to log file mmh_verify_${DT}.log"
    ${MIRRORMGRPATH}/mirrormgr verify registry --path ${MIRRORPATH} --log-file mmh_verify_${DT}.log    
    echo "==============================================="
    echo "Mirror Manager Helper: Downloaded release verification: ls -l ${MIRRORPATH}/lod/${CADENCE}/${VERSION}"    
    ls -l ${MIRRORPATH}/lod/${CADENCE}/${VERSION}
}

# get repo names from SAS and create equivalent repos in ECR
upload_step1() {
    echo "==============================================="
    echo "Mirror Manager Helper: Uploading repo step1 creating ECR repos."
    for repo in $($MIRRORMGRPATH/mirrormgr list target docker repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${NS}) ; do
        echo "Working on SAS repo: $repo"
        aws ecr describe-repositories $AWS_CLI_PARMS --repository-names $repo || aws ecr create-repository $AWS_CLI_PARMS --repository-name $repo
    done
}

# upload downloaded SAS images to ECR repos
upload_step2() {
    echo "==============================================="
    echo "Mirror Manager Helper: Uploading repo step2 uploading images. Writing to log file mmh_upload_${DT}.log"
    ${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${ECRURL}/${NS} --username 'AWS' --password $(aws ecr get-login-password $AWS_CLI_PARMS) --push-only --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file mmh_upload_${DT}.log
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