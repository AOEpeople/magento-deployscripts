#!/bin/bash -e

function usage {
    echo "Usage:"
    echo " $0 -s <stackId> -a <appId> -p <profile> -c <command> -C <custom JSON>"
    echo " -s   stack id";
    echo " -a   app id";
    echo " -p   aws cli profile";
    echo " -c   command";
    echo " -C   custom json (Limted to 80kb, needs to be escaped)"
    echo ""
    echo "Example:"
    echo "BUILD=82; $0 -p magento-build-uploads -s 484ddf88-b89f-42a5-ada9-e0f6d0870e83 -a 13db9a00-4398-43b3-99c7-8671490814c0 -c '{\"Name\":\"deploy\"}'"
    exit $1
}

while getopts 'a:s:c:C:p:' OPTION ; do
case "${OPTION}" in
        s) AWS_STACKID="${OPTARG}";;
        a) AWS_APPID="${OPTARG}";;
        c) COMMAND="${OPTARG}";;
        C) JSON="${OPTARG}";;
        p) PROFILE="${OPTARG}";;
        \?) echo; usage 1;;
    esac
done

if [ -z "${AWS_STACKID}" ]; then echo "ERROR: Please provide a stack id (-s <stackId>)"; exit 1; fi
if [ -z "${AWS_APPID}" ]; then echo "ERROR: Please provide an app id (-a <appId>)"; exit 1; fi
if [ -z "${COMMAND}" ]; then echo "ERROR: Please provide a command (-c <command>)"; exit 1; fi
if [ -z "${PROFILE}" ]; then echo "ERROR: Please provide a aws cli profile (-p <profile>)"; exit 1; fi

if [ -z "${JSON}" ]; then
    CUSTOM_JSON=""
else
    CUSTOM_JSON="--custom-json ${JSON}"
fi

AWSCLI="aws --profile ${PROFILE} --region us-east-1 opsworks"

echo "Triggering deployment on app ${AWS_APPID}"
DEPLOYMENT_ID=`${AWSCLI} create-deployment --stack-id "${AWS_STACKID}" --app-id "${AWS_APPID}" --command "${COMMAND}" ${CUSTOM_JSON} | jq '.DeploymentId'  | sed 's/\"//g'`

echo "Deployment Id: ${DEPLOYMENT_ID}"
echo "https://console.aws.amazon.com/opsworks/home#/stack/${AWS_STACKID}/deployments/${DEPLOYMENT_ID}"

COUNTER=0
while [ $COUNTER -lt 20 ]; do
    sleep 30s
    echo "Polling status..."
    STATUS=`${AWSCLI} describe-deployments --deployment-ids "${DEPLOYMENT_ID}" | jq '.Deployments[0].Status'  | sed 's/\"//g'`
    echo "Status: ${STATUS}"
    if [ "${STATUS}" = 'failed' ] ; then exit 1; fi
    if [ "${STATUS}" = 'successful' ] ; then exit 0; fi
    let COUNTER=COUNTER+1
done

echo "Deployment timed out"
exit 1