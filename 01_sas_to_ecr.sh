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

common() {
  echo "===============================================" | tee -a $1
  echo "CADENCE=${CADENCE}" | tee -a $1
  echo "VERSION=${VERSION}" | tee -a $1
  echo "RELEASE=${RELEASE}" | tee -a $1
}

# estimate size of to be downloaded mirror
estimate() {
    common /dev/null
    echo "==============================================="
    echo "Mirror Manager Helper: Size estimate for SAS repo ${MIRRORPATH} (can take a while)."
    ${MIRRORMGRPATH}/mirrormgr list remote repos size --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE}
}

# download SAS mirror
download() {
    LOGFILE="mmh_download_${DT}.log"
    CMD="${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS}"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Downloading SAS repo to ${MIRRORPATH}. Writing to log file ${LOGFILE}" | tee -a ${LOGFILE}
    echo "${CMD}" >> ${LOGFILE}
    eval "${CMD} --log-file ${LOGFILE}"
    #${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --deployment-assets ${ASSETSPATH}/${ASSETSFILE} --workers ${WORKERS} --log-file mmh_download.log    
    #${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file mmh_download_${DT}.log
}

# verify downloaded mirror and output downloaded release info 
verify() {
    LOGFILE="mmh_verify_${DT}.log"
    CMD="${MIRRORMGRPATH}/mirrormgr verify registry --path ${MIRRORPATH}"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Verifying repo ${MIRRORPATH}. Writing to log file ${LOGFILE}" | tee -a ${LOGFILE}
    echo "${CMD}" >> ${LOGFILE}
    eval "${CMD} --log-file ${LOGFILE}"
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Downloaded release verification: ls -l ${MIRRORPATH}/lod/${CADENCE}/${VERSION}" | tee -a ${LOGFILE}
    CMD="ls -l ${MIRRORPATH}/lod/${CADENCE}/${VERSION}"
    echo "${CMD} >> ${LOGFILE}"
    eval "${CMD} | tee -a ${LOGFILE}"
}

# get repo names from SAS and create equivalent repos in ECR
upload_step1() {
    common /dev/null
    echo "==============================================="
    echo "Mirror Manager Helper: Uploading repo step1 creating ECR repos."
    for repo in $($MIRRORMGRPATH/mirrormgr list target docker repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${NS}) ; do
        echo "Working on SAS repo: $repo"
        aws ecr describe-repositories $AWS_CLI_PARMS --repository-names $repo || aws ecr create-repository $AWS_CLI_PARMS --repository-name $repo
    done
}

# upload downloaded SAS images to ECR repos
upload_step2() {
    LOGFILE="mmh_upload_${DT}.log"
    CMD="${MIRRORMGRPATH}/mirrormgr mirror registry --path ${MIRRORPATH} --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${ECRURL}/${NS} --push-only --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS}"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Uploading repo step2 uploading images. Writing to log file ${LOGFILE}" | tee -a ${LOGFILE}
    echo "${CMD}" >> ${LOGFILE}
    eval "${CMD} --log-file ${LOGFILE} --username 'AWS' --password $(aws ecr get-login-password $AWS_CLI_PARMS)"
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