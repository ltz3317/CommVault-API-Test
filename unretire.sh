#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

if [ "$APPNAME" = "Virtual Server" ]
then
	## Fallback subclient ##

	disp "Falling back subclient for $APPNAME."
	eval $CURLCMD -d @retire_subclient_vsa-fallback.xml -L \"$BASEURI"/Subclient/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM".retired',subclientName='"$VM".retired')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

	## Fallback backupset name ##

	disp "Falling back backupset name for $APPNAME."
        eval $CURLCMD -d @rename_backupset_vsa-fallback.xml -L \"$BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM".retired')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
else
	## Get client information ##
	
	disp "Getting client ID by client name."
	ORICLIENTNAME=$CLIENTNAME
	export CLIENTNAME=$CLIENTNAME.retired
	echo "Client Name: $CLIENTNAME"
	
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"
	
	## Fallback client name and host name ##
	disp "Falling back client name and host name."
	eval $CURLCMD -d @client_prop-retire_fallback.xml -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
	
	## Reconfigure client licenses ##
	
	disp "Reconfiguring client licenses."
	export CLIENTNAME=$ORICLIENTNAME
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" reconfigure_client.xml
	eval $CURLCMD -d @reconfigure_client.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n
fi

