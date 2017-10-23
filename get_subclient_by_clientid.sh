#!/bin/sh

if [ "$APPNAME" = "Virtual Server" ]
then
	eval $CURLCMD -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and @backupsetName='$VM']" -v @subclientName -o ":"  -v @subclientId
else
	eval $CURLCMD -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and not(@subclientName='(command line)')]" -v @subclientName -o ":"  -v @subclientId
fi
