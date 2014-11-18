#!/bin/bash

# @author Fabrizio Branca
# @since 2014-03-30

if [[ -z "${USERNAME}" ]]; then
    echo "No username found. Please set your username (the one from integration53d) by doing:"
    echo 'export USERNAME="your.username"'
    echo "(You might want to add this line to your ~/.bashrc file, so you don't have to do this over and over again"
    echo "Also please make sure you have agent forwarding enabled in your ssh client"
    exit 1
fi

PROJECT='itouchless'
MASTERSYSTEM='deploy'

REMOTESYSTEMSTORAGE="${USERNAME}@integration53d.aoe-works.de:/home/systemstorage/systemstorage/${PROJECT}/backup/${MASTERSYSTEM}"
LOCALSYSTEMSSTORAGE="/home/systemstorage/systemstorage/${PROJECT}/backup/${MASTERSYSTEM}"

echo "Downloading database dump"
rsync -av --omit-dir-times "${REMOTESYSTEMSTORAGE}/database/" "${LOCALSYSTEMSSTORAGE}/database/"

echo "Downloading (minified) media folder"
rsync -av --omit-dir-times "${REMOTESYSTEMSTORAGE}/files/" "${LOCALSYSTEMSSTORAGE}/files/"

