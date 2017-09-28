#!/bin/sh

if [ "$APPNAME" = "Virtual Server" ]
then
	# curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and @subclientName='subclient-$VM']" -v @subclientName -o ":"  -v @subclientId
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and @backupsetName='backupset-$VM']" -v @subclientName -o ":"  -v @subclientId
else
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and not(@subclientName='(command line)')]" -v @subclientName -o ":"  -v @subclientId
fi
