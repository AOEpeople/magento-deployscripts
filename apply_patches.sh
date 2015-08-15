#!/bin/bash

# This script assume it's being executed in the Magento root directory
# and that the patches (*.diff) sit in ../patches

# some basic checks
if [ ! -f 'index.php' ] ; then echo "Could not find index.php"; exit 1 ; fi
if [ ! -d 'app/etc' ] ; then echo "Could not find app/etc"; exit 1 ; fi
if [ ! -d 'app/code' ] ; then echo "Could not find app/code"; exit 1 ; fi
if [ ! -d '../patches' ] ; then echo "Could not find ../patches"; exit 1 ; fi


PATCH_BIN=`which patch`

apply() {
    DRY_RUN_FLAG=
    FILE=$1
    if [ "$2" = "dry-run" ] ; then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=$($PATCH_BIN $DRY_RUN_FLAG -p1 -i "$FILE");
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

find ../patches -iname '*.diff' -print0 | while read -d $'\0' file; do
    filename=$(basename "$file")
    if [ -f applied_patches.txt ] && grep -Fxq "$filename" applied_patches.txt; then
        echo "File $filename was already applied before"
    else
        echo "Applying file $filename"
        apply "$file" dry-run
        apply "$file"
        echo "$filename" >> applied_patches.txt
        echo "Patch $filename applied successfully"
    fi
done

