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

# helper function to check if AWS CLI is authenticated or not
verify_aws_auth() {
    aws sts get-caller-identity > /dev/null 2>&1
    if [ $? -ne 0 ]; then
       echo "Error: AWS CLI is not authenticated to AWS, fix and re-run. Exiting."
       exit 1
    fi
}

# helper funtions with common output 
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
    echo "Mirror Manager Helper: Size estimate for SAS repo ${DOWNLOADPATH}/sas_repos (can take a while)."
    ${MIRRORMGRPATH}/mirrormgr list remote repos size --path ${DOWNLOADPATH}/sas_repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE}
}

# download SAS mirror
download() {
    LOGFILE="Logs/mmh_download_${DT}.log"
    CMD="${MIRRORMGRPATH}/mirrormgr mirror registry --path ${DOWNLOADPATH}/sas_repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file ${LOGFILE}"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Downloading SAS repo to ${DOWNLOADPATH}/sas_repos." | tee -a ${LOGFILE}
    echo "Writing to log file ${LOGFILE}"
    echo "${CMD}" >> ${LOGFILE}
    eval "${CMD}"
    echo "Mirror Manager Helper: Downloading list of SAS repos to ${DOWNLOADPATH}/sas_repos_${CADENCE}_${VERSION}_${RELEASE}.txt" | tee -a ${LOGFILE}
    $MIRRORMGRPATH/mirrormgr list target docker repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${NS} > ${DOWNLOADPATH}/sas_repos_${CADENCE}_${VERSION}_${RELEASE}.txt
    #${MIRRORMGRPATH}/mirrormgr mirror registry --path ${DOWNLOADPATH}/sas_repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --deployment-assets ${ASSETSPATH}/${ASSETSFILE} --workers ${WORKERS} --log-file mmh_download.log    
    #${MIRRORMGRPATH}/mirrormgr mirror registry --path ${DOWNLOADPATH}/sas_repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file mmh_download_${DT}.log
}

# verify downloaded mirror and output downloaded release info 
verify() {
    LOGFILE="Logs/mmh_verify_${DT}.log"
    CMD="${MIRRORMGRPATH}/mirrormgr verify registry --path ${DOWNLOADPATH}/sas_repos --log-file ${LOGFILE}"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Verifying repo ${DOWNLOADPATH}/sas_repos." | tee -a ${LOGFILE}
    echo "Writing to log file ${LOGFILE}"
    echo "${CMD}" >> ${LOGFILE}
    eval "${CMD}"
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Downloaded release verification: ls -l ${DOWNLOADPATH}/sas_repos/lod/${CADENCE}/${VERSION}" | tee -a ${LOGFILE}
    CMD="ls -l ${DOWNLOADPATH}/sas_repos/lod/${CADENCE}/${VERSION}"
    echo "${CMD} >> ${LOGFILE}"
    eval "${CMD} | tee -a ${LOGFILE}"
}

# get repo names from SAS and create equivalent repos in ECR
create_ecr_repos() {
    verify_aws_auth
    if [ ! -f "${DOWNLOADPATH}/sas_repos_${CADENCE}_${VERSION}_${RELEASE}.txt" ]; then
       echo "Error: SAS repos list file not found. Exiting."
       exit 1
    fi
    LOGFILE="Logs/mmh_create_ecr_repos_${DT}.log"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Creating ECR repos." | tee -a ${LOGFILE}
    echo "Writing to log file ${LOGFILE}"        
    echo "Creating $(cat ${DOWNLOADPATH}/sas_repos_${CADENCE}_${VERSION}_${RELEASE}.txt | wc -l) repos in ECR"
    while read repo; do
        echo "Working on SAS repo: $repo" | tee -a ${LOGFILE}
        (aws ecr describe-repositories $AWS_CLI_PARMS --repository-names $repo || aws ecr create-repository $AWS_CLI_PARMS --repository-name $repo) | tee -a ${LOGFILE}
    done < ${DOWNLOADPATH}/sas_repos_${CADENCE}_${VERSION}_${RELEASE}.txt
}

# upload downloaded SAS images to ECR repos
# CMD intentionally does not include the --username and --password parameters to they can be masked
upload_to_ecr() {
    verify_aws_auth
    LOGFILE="Logs/mmh_upload_to_ecr_${DT}.log"
    CMD="${MIRRORMGRPATH}/mirrormgr mirror registry --path ${DOWNLOADPATH}/sas_repos --deployment-data ${ASSETSPATH}/${CERTSFILE} --destination ${ECRURL}/${NS} --push-only --cadence ${CADENCE}-${VERSION} --release ${RELEASE} --workers ${WORKERS} --log-file ${LOGFILE}"
    common $LOGFILE
    echo "===============================================" | tee -a ${LOGFILE}
    echo "Mirror Manager Helper: Uploading SAS docker images to ECR repos." | tee -a ${LOGFILE}
    echo "Writing to log file ${LOGFILE}"
    echo "${CMD} --username 'AWS' --password <masked>" >> ${LOGFILE}
    eval "${CMD} --username 'AWS' --password $(aws ecr get-login-password $AWS_CLI_PARMS)"
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
    create_ecr_repos
    upload_to_ecr
    ;;
  "create_ecr_repos")
    create_ecr_repos
    ;;
  "upload_to_ecr")
    upload_to_ecr
    ;;
  *)
    echo "Usage: 01_sas_to_ecr.sh [estimate|download|verify|upload|create_ecr_repos|upload_to_ecr]"    
    ;;
esac