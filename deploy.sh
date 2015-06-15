#!/bin/bash

# Magento Deployment Script
# Author: Fabrizio Branca

function usage {
    echo ""
    echo "Usage:"
    echo ""
    echo "$0 -r <packageUrl> -t <targetDir> -e <environment> [-u <downloadUsername>] [-p <downloadPassword>] [-a <awsCliProfile>] [-d] [-c]"
    echo ""
    echo "   -r     Package url (http, S3 or local file)"
    echo "   -t     Target dir"
    echo "   -d     Also download and install .extra.tar.gz package"
    echo ""
    echo "          [http(s)]"
    echo "   -u     Download username (only used for packages via http(s))"
    echo "   -p     Download password (only used for packages via http(s))"
    echo ""
    echo "          [aws cli (default)]"
    echo "   -a     aws cli profile, defaults to 'default' (only used for aws cli, not s3cmd)"
    echo ""
    echo "          [s3cmd]"
    echo "   -c     Use s3cmd instead of aws cli to download the package"
    echo ""
    echo ""
    echo "Examples:"
    echo "  Install extra package on devbox (note the -d option):"
    echo "    B=42; $0 -d -e devbox -r s3://mybucket/jobs/acme_build/$B/acme.tar.gz -t /var/www/acme/devbox/ -a awscliprofile"
    echo "  Install production package:"
    echo "    B=42; $0 -e production -r s3://mybucket/jobs/acme_build/$B/acme.tar.gz -t /var/www/acme/production/ -a awscliprofile"
    echo "  Install via http:"
    echo "    B=42; $0 -e production -r http://jenkins/jobs/acme_build/$B/acme.tar.gz -u username -p password -t /var/www/acme/production/"
    echo "  Install via local file:"
    echo "    B=42; $0 -e production -r /path/to/$B/acme.tar.gz -t /var/www/acme/integration/"
    echo "  Use s3cmd instead of aws cli (note the -c option). s3cmd must already be configured at this point."
    echo "    B=42; $0 -e devbox -c s3://mybucket/jobs/acme_build/$B/acme.tar.gz -t /var/www/acme/production/"
    echo ""
    exit $1
}

AWSCLIPROFILE='default'
EXTRA=0
USES3CMD=0

while getopts 'r:t:u:p:e:a:dc' OPTION ; do
case "${OPTION}" in
        r) PACKAGEURL="${OPTARG}";;
        t) ENVROOTDIR="${OPTARG}";;
        u) USERNAME="${OPTARG}";;
        p) PASSWORD="${OPTARG}";;
        e) ENVIRONMENT="${OPTARG}";;
        a) AWSCLIPROFILE="${OPTARG}";;
        d) EXTRA=1;;
        c) USES3CMD=1;;
        \?) echo; usage 1;;
    esac
done

if [ -z "${ENVIRONMENT}" ]; then echo "ERROR: Please provide an environment code (e.g. -e staging)"; usage 1; fi

# Check if releases folder exists
RELEASES="${ENVROOTDIR}/releases"
RELEASENAME="build_$(date +%Y%m%d%H%M%S)"
RELEASEFOLDER="${RELEASES}/${RELEASENAME}"
if [ ! -d "${RELEASES}" ] ; then echo "Releases dir ${RELEASES} not found"; usage 1; fi
if [ -d "${RELEASEFOLDER}" ] ; then echo "Release folder ${RELEASEFOLDER} already exists"; exit 1; fi

# Check if the shared folder exists (but creating the symlinks is the installer script's responsibilty)
SHAREDFOLDER="${ENVROOTDIR}/shared"
SHAREDFOLDERS=( "var" "media" )
if [ ! -d "${SHAREDFOLDER}" ] ; then echo "Shared folder ${SHAREDFOLDER} not found"; exit 1; fi
for i in "${SHAREDFOLDERS[@]}" ; do if [ ! -d "${SHAREDFOLDER}/$i" ] ; then echo "Shared folder ${SHAREDFOLDER}/$i not found"; exit 1; fi; done


# Create tmp dir and make sure it's going to be deleted in any case
TMPDIR=`mktemp -d`
function cleanup {
    echo "Removing temp dir ${TMPDIR}"
    rm -rf "${TMPDIR}"
}
trap cleanup EXIT

EXTRAPACKAGEURL=${PACKAGEURL/.tar.gz/.extra.tar.gz}


########################################################################################################################
# Step 1: get the package via http, S3 or local file
########################################################################################################################

if [ -f "${PACKAGEURL}" ] ; then
    cp "${PACKAGEURL}" "${TMPDIR}/package.tar.gz" || { echo "Error while copying base package" ; exit 1; }
    if [ ! -z "${EXTRA}" ] ; then
        cp "${EXTRAPACKAGEURL}" "${TMPDIR}/package.extra.tar.gz" || { echo "Error while copying extra package" ; exit 1; }
    fi
elif [[ "${PACKAGEURL}" =~ ^https?:// ]] ; then
    if [ ! -z "${USERNAME}" ] && [ ! -z "${PASSWORD}" ] ; then
        CREDENTIALS="--user='${USERNAME}' --password='${PASSWORD}'"
    fi
    echo "Downloading package via http"
    wget --auth-no-challenge "${CREDENTIALS}" "${PACKAGEURL}" -O "${TMPDIR}/package.tar.gz" || { echo "Error while downloading base package from http" ; exit 1; }
    if [ ! -z "${EXTRA}" ] ; then
        echo "Downloading extra package via http"
        wget --auth-no-challenge "${CREDENTIALS}" "${EXTRAPACKAGEURL}" -O "${TMPDIR}/package.extra.tar.gz" || { echo "Error while downloading extra package from http" ; exit 1; }
    fi
elif [[ "${PACKAGEURL}" =~ ^s3:// ]] ; then
    echo -n "Downloading base package via S3"
    if [ -z "${USES3CMD}" ] ; then
        echo " (via aws cli)";
        aws --profile ${AWSCLIPROFILE} s3 cp "${PACKAGEURL}" "${TMPDIR}/package.tar.gz" || { echo "Error while downloading base package from S3" ; exit 1; }
    else
        echo " (via s3cmd)";
        s3cmd get "${PACKAGEURL}" "${TMPDIR}/package.tar.gz" || { echo "Error while downloading base package from S3" ; exit 1; }
    fi
    if [ ! -z "${EXTRA}" ] ; then
        echo -n "Downloading extra package via S3"
        if [ -z "${USES3CMD}" ] ; then
            echo " (via aws cli)";
            aws --profile ${AWSCLIPROFILE} s3 cp "${EXTRAPACKAGEURL}" "${TMPDIR}/package.extra.tar.gz" || { echo "Error while downloading extra package from S3" ; exit 1; }
        else
            echo " (via s3cmd)";
            s3cmd get "${EXTRAPACKAGEURL}" "${TMPDIR}/package.extra.tar.gz" || { echo "Error while downloading extra package from S3" ; exit 1; }
        fi
    fi
fi




########################################################################################################################
# Step 2: extract files into release folder
########################################################################################################################

echo "Extracting base package"
tar xzf "${TMPDIR}/package.tar.gz" -C "${RELEASEFOLDER}/package" || { echo "Error while extracting base package" ; exit 1; }

if [ ! -z "${EXTRA}" ] ; then
    echo "Extracting extra package on top of base package"
    tar xzf "${TMPDIR}/package.extra.tar.gz" -C "${RELEASEFOLDER}/package" || { echo "Error while extracting extra package" ; exit 1; }
fi




########################################################################################################################
# Step 3: Trigger installation
########################################################################################################################

if [ ! -f "${RELEASEFOLDER}/tools/install.sh" ] ; then echo "Could not find installer" ; exit 1; fi
${RELEASEFOLDER}/tools/install.sh -e "${ENVIRONMENT}" || { echo "Installing package failed"; exit 1; }




########################################################################################################################
# Step 4: Update symlink
########################################################################################################################

echo
echo "Updating release symlink"
echo "------------------------"

echo "Settings current (${RELEASES}/current) to release folder (${RELEASENAME})"
ln -sfn "${RELEASENAME}" "${RELEASES}/current" || { echo "Error while symlinking 'current' to release folder" ; exit 1; }

echo "--> THIS PACKAGE IS LIVE NOW! <--"