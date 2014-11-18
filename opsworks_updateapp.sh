#!/bin/bash -e

function usage {
    echo "Usage:"
    echo " $0 -a <appId> -u <packageUrl> -p <profile>"
    echo " -a   app id";
    echo " -u   package url";
    echo " -p   aws cli profile";
    echo ""
    echo "Example:"
    echo "BUILD=82; $0 -p magento-build-uploads -a 13db9a00-4398-43b3-99c7-8671490814c0 -u https://anki-magento-builds.s3-us-west-2.amazonaws.com/jobs/anki_build_develop/\${BUILD}/anki.tar.gz"
    exit $1
}

while getopts 'a:u:p:' OPTION ; do
case "${OPTION}" in
        a) AWS_APPID="${OPTARG}";;
        u) PACKAGEURL="${OPTARG}";;
        p) PROFILE="${OPTARG}";;
        \?) echo; usage 1;;
    esac
done

if [ -z "${AWS_APPID}" ]; then echo "ERROR: Please provide an app id (-a <appId>)"; exit 1; fi
if [ -z "${PACKAGEURL}" ]; then echo "ERROR: Please provide a package url (-u <packageUrl>)"; exit 1; fi
if [ -z "${PROFILE}" ]; then echo "ERROR: Please provide a aws cli profile (-p <profile>)"; exit 1; fi

AWSCLI="aws --profile ${PROFILE} --region us-east-1 opsworks"

echo "Updating app ${AWS_APPID} to Url=${PACKAGEURL}"
${AWSCLI} update-app --app-id "${AWS_APPID}" --app-source "Url=${PACKAGEURL}"
