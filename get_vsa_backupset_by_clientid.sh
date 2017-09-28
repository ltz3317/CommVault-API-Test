#!/bin/sh

curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/Backupset?clientId=$CLIENTID" | xmlstarlet sel -t -m "//backupSetEntity[@backupsetName='backupset-$VM']" -v @backupsetName -o ":" -v @backupsetId
