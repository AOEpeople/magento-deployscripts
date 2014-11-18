#!/bin/bash -e

# Get absolute path to main directory
ABSPATH=$(cd "${0%/*}" 2>/dev/null; echo "${PWD}/${0##*/}")
SOURCE_DIR=`dirname "${ABSPATH}"`


function usage {
    echo "Usage:"
    echo "$0 -p <projectWebRootPath> -s <systemStorageRootPath>"
    echo "    -p <projectWebRootPath>       Project web root path (htdocs)"
    echo "    -s <systemStorageRootPath>    Systemstorage project root path"
    echo ""
    echo "Example:"
    echo "    -p /var/www/projectname/deploy/htdocs -s /home/systemstorage/systemstorage/projectname/backup/deploy"
    exit $1
}

# Process options
while getopts 'p:s:' OPTION ; do
    case "${OPTION}" in
        p) PROJECT_WEBROOT=`echo "${OPTARG}" | sed -e "s/\/*$//" `;; # delete last slash
        s) SYSTEMSTORAGE_LOCAL=`echo "${OPTARG}" | sed -e "s/\/*$//" `;; # delete last slash
        \?) echo; usage 1;;
    esac
done

if [ ! -d "${PROJECT_WEBROOT}" ] ; then echo "Could not find project root ${PROJECT_WEBROOT}" ; usage 1; fi
if [ ! -f "${PROJECT_WEBROOT}/index.php" ] ; then echo "Invalid ${PROJECT_WEBROOT} (could not find index.php)" ; usage 1; fi

if [ ! -d "${SYSTEMSTORAGE_LOCAL}" ] ; then echo "Could not find systemstorage project root $SYSTEMSTORAGE_LOCAL" ; usage 1; fi
if [ ! -d "${SYSTEMSTORAGE_LOCAL}/database" ] ; then echo "Invalid $SYSTEMSTORAGE_LOCAL (could not find database folder)" ; exit 1; fi
if [ ! -d "${SYSTEMSTORAGE_LOCAL}/files" ] ; then echo "Invalid $SYSTEMSTORAGE_LOCAL (could not find files folder)" ; usage 1; fi


# Create database dump
touch "${PROJECT_WEBROOT}/var/db_dump_in_progress.lock"
/usr/bin/php -d apc.enable_cli=0 ${SOURCE_DIR}/n98-magerun.phar \
        --root-dir=${PROJECT_WEBROOT} \
        -q \
        db:dump \
        --compression=gzip \
        --strip="@stripped m2epro_* catalogsearch_fulltext_cl report_event log* report_compared_product_index report_viewed_product_index index_event index_process_event catalog_product_flat_* asynccache* enterprise_logging_event* core_cache core_cache_tag" \
        ${SYSTEMSTORAGE_LOCAL}/database/combined_dump.sql
date +%s > ${SYSTEMSTORAGE_LOCAL}/database/created.txt
rm "${PROJECT_WEBROOT}/var/db_dump_in_progress.lock"

# Backup files
rsync \
--archive \
--no-o --no-p --no-g \
--force \
--omit-dir-times \
--ignore-errors \
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
"${PROJECT_WEBROOT}/media/" "${SYSTEMSTORAGE_LOCAL}/files/"

date +%s > ${SYSTEMSTORAGE_LOCAL}/files/created.txt
