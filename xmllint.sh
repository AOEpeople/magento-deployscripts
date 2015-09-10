#!/bin/bash

if [ ! -d $1 ] ; then
    echo "Invalid dir"
    exit 1
fi

command_exists () {
    type "$1" &> /dev/null ;
}

FILES=`find $1 -type f -name "*.xml"`

if command_exists xmllint ; then
    for i in $FILES; do
        xmllint --noout "$i" || { echo "Unable to parse file '$i'"; exit 1; }
        echo "No syntax errors detected in $i"
    done
else
    echo "Could not find xmllint. Using PHP instead..."
    for i in $FILES; do
        php -r "if (@simplexml_load_file('$i') === false) exit(1);" || { echo "Unable to parse file '$i'"; exit 1; }
        echo "No syntax errors detected in $i"
    done
fi