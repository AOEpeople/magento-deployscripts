#!/bin/bash

if [ ! -d $1 ] ; then
    echo "Invalid dir"
    exit 1
fi

# Run in parallel:
# find -L $1 \( -name '*.php' -o -name '*.phtml' \) -print0 | xargs -0 -n 1 -P 20 php -l

FILES=`find $1 -type f \( -name '*.php' -o -name '*.phtml' \)`

TMP_FILE=/tmp/xmllint.tmp
touch $TMP_FILE;

for i in $FILES; do
    md5=($(md5sum $i));
    if grep -Fxq "$md5" $TMP_FILE; then
        echo "No syntax errors detected in $i (cached)"
    else
        php -l "$i" || { echo "Unable to parse file '$i'"; exit 1; }
        echo $md5 >> $TMP_FILE
        echo "No syntax errors detected in $i"
    fi
done
