#!/bin/bash

if [ ! -d $1 ] ; then
    echo "Invalid dir"
    exit 1
fi

command_exists () {
    type "$1" &> /dev/null ;
}

FILES=`find $1 -type f -name "*.xml"`

TMP_FILE=/tmp/xmllint.tmp
touch $TMP_FILE;

if command_exists xmllint ; then
    for i in $FILES; do
        md5=($(md5sum $i));
        if grep -Fxq "$md5" $TMP_FILE; then
            echo "No syntax errors detected in $i (cached)"
        else
            xmllint --noout "$i" || { echo "Unable to parse file '$i'"; exit 1; }
            echo $md5 >> $TMP_FILE
            echo "No syntax errors detected in $i"
        fi
    done
else
    echo "Could not find xmllint. Using PHP instead..."
    for i in $FILES; do
        md5=($(md5sum $i));
        if grep -Fxq "$md5" $TMP_FILE; then
            echo "No syntax errors detected in $i (cached)"
        else
            php -r "if (@simplexml_load_file('$i') === false) exit(1);" || { echo "Unable to parse file '$i'"; exit 1; }
            echo $md5 >> $TMP_FILE
            echo "No syntax errors detected in $i"
        fi
    done
fi