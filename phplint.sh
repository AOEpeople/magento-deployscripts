#!/bin/bash

if [ ! -d $1 ] ; then
	echo "Invalid dir"
	exit 1
fi

FILES=`find $1 -type f -name "*.php"`

for i in $FILES; do
	php -l "$i" || exit 1;
done
