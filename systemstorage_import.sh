#!/bin/bash -e

# Get absolute path to main directory
ABSPATH=$(cd "${0%/*}" 2>/dev/null; echo "${PWD}/${0##*/}")
SOURCE_DIR=`dirname "${ABSPATH}"`

function usage {
    echo "Usage:"
    echo "$0 -p <projectWebRootPath> -s <systemStorageRootPath> [-a <awsCliProfile>] [-f]"
    echo "    -p <projectWebRootPath>       Project web root path (htdocs)"
    echo "    -s <systemStorageRootPath>    Systemstorage project root path"
    echo "    -f                            If set file will be skipped (database only)"
    echo ""
    echo "Example:"
    echo "    -p /var/www/projectname/deploy/htdocs -s /home/systemstorage/systemstorage/projectname/backup/deploy"
    exit $1
}


# Process options
while getopts 'p:s:a:f' OPTION ; do
    case "${OPTION}" in
        p) PROJECT_WEBROOT=`echo "${OPTARG}" | sed -e "s/\/*$//" `;; # delete last slash
        s) SYSTEMSTORAGEPATH=`echo "${OPTARG}" | sed -e "s/\/*$//" `;; # delete last slash
        a) AWSCLIPROFILE=${OPTARG};;
        f) SKIPFILES=1;;
        \?) echo; usage 1;;
    esac
done

if [ ! -d "${PROJECT_WEBROOT}" ] ; then echo "Could not find project root ${PROJECT_WEBROOT}" ; usage 1; fi
if [ ! -f "${PROJECT_WEBROOT}/index.php" ] ; then echo "Invalid ${PROJECT_WEBROOT} (could not find index.php)" ; usage 1; fi


function cleanup {
    echo "Removing temp dir ${TMPDIR}"
    rm -rf "${SYSTEMSTORAGE_LOCAL}"
}

if [[ "${SYSTEMSTORAGEPATH}" =~ ^s3:// ]] ; then
    SYSTEMSTORAGE_LOCAL=`mktemp -d`
    trap cleanup EXIT

    PROFILEPARAM=""
    if [ ! -z "${AWSCLIPROFILE}" ] ; then
        PROFILEPARAM="--profile ${AWSCLIPROFILE}"
    fi
    echo "Downloading systemstorage from S3"
    aws ${PROFILEPARAM} s3 sync --exact-timestamps --delete "${SYSTEMSTORAGEPATH}" "${SYSTEMSTORAGE_LOCAL}" || { echo "Error while syncing files from S3 to local" ; exit 1; }
else
    SYSTEMSTORAGE_LOCAL=${SYSTEMSTORAGEPATH}
fi


if [ ! -d "${SYSTEMSTORAGE_LOCAL}" ] ; then echo "Could not find systemstorage project root $SYSTEMSTORAGE_LOCAL" ; usage 1; fi
if [ ! -d "${SYSTEMSTORAGE_LOCAL}/database" ] ; then echo "Invalid $SYSTEMSTORAGE_LOCAL (could not find database folder)" ; exit 1; fi
if [ ! -f "${SYSTEMSTORAGE_LOCAL}/database/combined_dump.sql.gz" ] ; then echo "Invalid $SYSTEMSTORAGE_LOCAL (could not find combined_dump.sql.gz)" ; exit 1; fi
if [ ! -f "${SYSTEMSTORAGE_LOCAL}/database/created.txt" ] ; then echo "Invalid $SYSTEMSTORAGE_LOCAL (created.txt)" ; exit 1; fi

if [ -z "${SKIPFILES}" ] ; then
    if [ ! -d "${SYSTEMSTORAGE_LOCAL}/files" ] ; then echo "Invalid $SYSTEMSTORAGE_LOCAL (could not find files folder)" ; usage 1; fi
fi


n98="/usr/bin/php -d apc.enable_cli=0 ${SOURCE_DIR}/n98-magerun.phar --root-dir=${PROJECT_WEBROOT}"


# 1 day
echo "Checking age ..."
MAX_AGE=86400

NOW=`date +%s`


DB_CREATED=`cat ${SYSTEMSTORAGE_LOCAL}/database/created.txt`
AGE_DB=$((NOW-DB_CREATED))
if [ "$AGE_DB" -lt "$MAX_AGE" ] ; then echo "DB age ok (${AGE_DB} sec)" ; else echo "Age of the database dump is too old (1 day max)" ; exit 1; fi;


if [ -z "${SKIPFILES}" ] ; then
    FILES_CREATED=`cat ${SYSTEMSTORAGE_LOCAL}/files/created.txt`
    AGE_FILES=$((NOW-FILES_CREATED))
    if [ "$AGE_FILES" -lt "$MAX_AGE" ] ; then echo "Files age ok (${AGE_FILES} sec)"; else echo "Age of the files dump is too old (1 day max)" ; exit 1; fi;
fi



# Importing database...
echo "Dropping all tables"
$n98 -q db:drop --tables --force || { echo "Error while dropping all tables"; exit 1; }

echo "Import database dump ${SYSTEMSTORAGE_LOCAL}/database/combined_dump.sql.gz"
$n98 -q db:import --compression=gzip "${SYSTEMSTORAGE_LOCAL}/database/combined_dump.sql.gz" ||  { echo "Error while importing dump"; exit 1; }



# Importing files...
if [ -z "${SKIPFILES}" ] ; then
    echo "Copy media folder"
    rsync \
    --archive \
    --force \
    --no-o --no-p --no-g \
    --omit-dir-times \
    --ignore-errors \
    --partial \
    --exclude=/catalog/product/cache/ \
    --exclude=/tmp/ \
    --exclude=.svn/ \
    --exclude=*/.svn/ \
    --exclude=.git/ \
    --exclude=*/.git/ \
    "${SYSTEMSTORAGE_LOCAL}/files/" "${PROJECT_WEBROOT}/media/"
fi
