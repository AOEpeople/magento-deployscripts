#!/bin/bash -e


# Get absolute path to main directory
ABSPATH=$(cd "${0%/*}" 2>/dev/null; echo "${PWD}/${0##*/}")
SOURCE_DIR=`dirname "${ABSPATH}"`

PROJECT="anki"

function usage {
    echo "Usage:"
    echo " $0 -e <environment>"
    echo " -e Environment (e.g. production, staging, devbox,...)"
    echo ""
    exit $1
}

SKIPIMPORTFROMSYSTEMSTORAGE=''

########## get argument-values
while getopts 'e:' OPTION ; do
case "${OPTION}" in
        e) ENVIRONMENT="${OPTARG}";;
        \?) echo; usage 1;;
    esac
done

VALID_ENVIRONMENTS=" production staging devbox latest deploy "
if [[ "${VALID_ENVIRONMENTS}" =~ " ${ENVIRONMENT} " ]] ; then
echo "Environment: ${ENVIRONMENT}"
else
echo "ERROR: Illegal environment code"
    exit 1;
fi

PROJECT_WEBROOT="/var/www/${PROJECT}/${ENVIRONMENT}/htdocs"

# BIN_DIR="/var/www/${PROJECT}/${ENVIRONMENT}/tools"
SYSTEMSTORAGE_LOCAL="/home/systemstorage/systemstorage/${PROJECT}/backup/${ENVIRONMENT}/"
SYSTEMSTORAGE_REMOTE="ssh-rrsync.${PROJECT}.integration53d.aoe-works.de:/home/systemstorage/systemstorage/${PROJECT}/backup/${ENVIRONMENT}/"

if [ ! -d "${SYSTEMSTORAGE_LOCAL}" ] ; then echo "${SYSTEMSTORAGE_LOCAL} does not exist"; exit 1; fi
if [ ! -d "${SYSTEMSTORAGE_LOCAL}database" ] ; then echo "${SYSTEMSTORAGE_LOCAL}database does not exist"; exit 1; fi
if [ ! -d "${SYSTEMSTORAGE_LOCAL}files" ] ; then echo "${SYSTEMSTORAGE_LOCAL}files does not exist"; exit 1; fi
if [ ! -d "${PROJECT_WEBROOT}" ] ; then echo "${PROJECT_WEBROOT} does not exist"; exit 1; fi

# Create database dump
touch "${PROJECT_WEBROOT}/var/db_dump_in_progress.lock"
/usr/bin/php -d apc.enable_cli=0 ${SOURCE_DIR}/n98-magerun.phar \
        --root-dir=${PROJECT_WEBROOT} \
        -q \
        db:dump \
        --compression=gzip \
        --strip="@stripped m2epro_* catalogsearch_fulltext_cl report_event log* report_compared_product_index report_viewed_product_index index_event index_process_event catalog_product_flat_* asynccache* enterprise_logging_event* core_cache core_cache_tag" \
        ${SYSTEMSTORAGE_LOCAL}database/combined_dump.sql
date +%s > ${SYSTEMSTORAGE_LOCAL}database/created.txt
rm "${PROJECT_WEBROOT}/var/db_dump_in_progress.lock"

# Backup files
rsync \
--no-o --no-p --no-g \
--force \
--omit-dir-times \
--ignore-errors \
--archive \
--partial \
--delete-after \
--delete-excluded \
--exclude=/catalog/product/cache/ \
--exclude=/catalog/product_*/ \
--exclude=/catalog/product/product/ \
--exclude=/export/ \
--exclude=/css/ \
--exclude=/js/ \
--exclude=/tmp/ \
--exclude=.svn/ \
--exclude=*/.svn/ \
--exclude=.git/ \
--exclude=*/.git/ \
"${PROJECT_WEBROOT}/media/" "${SYSTEMSTORAGE_LOCAL}files/"

date +%s > ${SYSTEMSTORAGE_LOCAL}files/created.txt

# Minify files
# php ${BIN_DIR}/BackupMinify/Bin/minify.php --source=${SYSTEMSTORAGE_LOCAL}files/ --target=${SYSTEMSTORAGE_LOCAL}files_minified/ --quietMode=1 &> /dev/null
# cp "${SYSTEMSTORAGE_LOCAL}files/created.txt" "${SYSTEMSTORAGE_LOCAL}files_minified/"


# Transfer to AOE server
# rsync -a --partial --omit-dir-times --delete-after ${SYSTEMSTORAGE_LOCAL}/database/ ${SYSTEMSTORAGE_REMOTE}/database/
# rsync -a --partial --omit-dir-times --delete-after ${SYSTEMSTORAGE_LOCAL}/files_minified/ ${SYSTEMSTORAGE_REMOTE}/files/

