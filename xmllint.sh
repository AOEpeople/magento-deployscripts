#!/bin/bash

if [ ! -d $1 ] ; then
	echo "Invalid dir"
	exit 1
fi

FILES=`find $1 -type f -name "*.xml"`

for i in $FILES; do
	php -r "if (@simplexml_load_file('$i') === false) exit(1);" || (echo "Unable to parse file '$i'"; exit 1)
	echo "No syntax errors detected in $i"
done
