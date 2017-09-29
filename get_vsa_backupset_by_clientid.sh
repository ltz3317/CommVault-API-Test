#!/bin/sh

eval $CURLCMD -L $BASEURI"/Backupset?clientId=$CLIENTID" | xmlstarlet sel -t -m "//backupSetEntity[@backupsetName='backupset-$VM']" -v @backupsetName -o ":" -v @backupsetId
