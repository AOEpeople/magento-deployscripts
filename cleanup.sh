#!/bin/bash

# Get absolute path to main directory
ABSPATH=$(cd "${0%/*}" 2>/dev/null; echo "${PWD}/${0##*/}")
SOURCE_DIR=`dirname "${ABSPATH}"`

function usage {
    echo "Usage:"
    echo " $0 -r <releasesDir> [-n <numberOfBuildsToKeep>]"
    echo " -r     Releases dir"
    echo " -n     Number of old builds to keep (current, latest and previous NOT included)"
    echo ""
    exit $1
}

NUMBEROFBUILDSTOKEEP=2

while getopts 'r:n:' OPTION ; do
case "${OPTION}" in
        r) RELEASES="${OPTARG}";;
        n) NUMBEROFBUILDSTOKEEP="${OPTARG}";;
        \?) echo; usage 1;;
    esac
done

if [ ! -d "${RELEASES}" ] ; then echo "Could not find releases dir ${RELEASES}"; usage 1; fi
if [ ! -L "${RELEASES}/current" ] ; then echo "No 'current' symlink found. This does not seem to be a valid release root dir"; usage 1; fi

cd ${RELEASES} || exit 1

SYMLINKS=()
SYMLINKS+=($(readlink -f "${RELEASES}/current"))
SYMLINKS+=($(readlink -f "${RELEASES}/latest"))
SYMLINKS+=($(readlink -f "${RELEASES}/previous"))

files=(`ls | grep build_ | sort -k2 -t_ -n -r | head -${NUMBEROFBUILDSTOKEEP}`)
for i in build_*; do

    I_PATH=$(readlink -f "$i")
    preserve=0;

    # Check if a symlink is pointing to this file:
    for a in ${SYMLINKS[@]}; do
        if [ "${I_PATH}" == "$a" ]; then
            preserve=1;
        fi;
    done;

    # Check whether this file is in files array:
    for a in ${files[@]}; do
        if [ "$i" == "$a" ]; then
            preserve=1;
        fi;
    done;

    # If it wasn't, delete it (or in this case, print filename)
    if [ $preserve == 0 ]; then
        echo "Deleting old deployment $i"
        rm -rf $i
    else
        echo "Skipping $i"
    fi;
done
