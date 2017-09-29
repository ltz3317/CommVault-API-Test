#!/bin/sh

eval $CURLCMD -L $BASEURI"/Backupset?clientId=$CLIENTID" | xmlstarlet sel -t -m "//backupSetEntity[@appName='$APPNAME']" -v @backupsetName -o ":" -v @backupsetId
