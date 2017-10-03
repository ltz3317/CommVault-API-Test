#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

if [ "$APPNAME" = "Virtual Server" ]
then
	## Rename backupset ##

	disp "Renaming backupset for $APPNAME".
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" rename_backupset_vsa.xml rename_backupset_vsa-fallback.xml
	sed -i "s/<backupsetName>.*<\/backupsetName>/<backupsetName>backupset-"$VM"<\/backupsetName>/g" rename_backupset_vsa.xml
	sed -i "s/<newBackupSetName>.*<\/newBackupSetName>/<newBackupSetName>"$VM".retired<\/newBackupSetName>/g" rename_backupset_vsa.xml
	sed -i "s/<backupsetName>.*<\/backupsetName>/<backupsetName>"$VM".retired<\/backupsetName>/g" rename_backupset_vsa-fallback.xml
	sed -i "s/<newBackupSetName>.*<\/newBackupSetName>/<newBackupSetName>backupset-"$VM"<\/newBackupSetName>/g" rename_backupset_vsa-fallback.xml
	eval $CURLCMD -d @rename_backupset_vsa.xml -L \"$BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='backupset-"$VM"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

	## Retire subclient ##

	disp "Retiring subclient for $APPNAME".
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" retire_subclient_vsa.xml retire_subclient_vsa-fallback.xml
	sed -i "s/<backupsetName>.*<\/backupsetName>/<backupsetName>"$VM".retired<\/backupsetName>/g" retire_subclient_vsa.xml retire_subclient_vsa-fallback.xml
	sed -i "s/<subclientName>.*<\/subclientName>/<subclientName>subclient-"$VM"<\/subclientName>/g" retire_subclient_vsa.xml
	sed -i "s/<newName>.*<\/newName>/<newName>"$VM".retired<\/newName>/g" retire_subclient_vsa.xml
	sed -i "s/<subclientName>.*<\/subclientName>/<subclientName>"$VM".retired<\/subclientName>/g" retire_subclient_vsa-fallback.xml
	sed -i "s/<newName>.*<\/newName>/<newName>subclient-"$VM"<\/newName>/g" retire_subclient_vsa-fallback.xml
	eval $CURLCMD -d @retire_subclient_vsa.xml -L \"$BASEURI"/Subclient/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM".retired',subclientName='subclient-"$VM"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
else
	## Get client information ##
	
	disp "Getting client ID by client name."
	echo "Client Name: $CLIENTNAME"
	
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"
	
	## Release client licenses ##
	
	disp "Releasing client licenses."
	sed -i "s/clientName=\".*\"/clientName=\"$CLIENTNAME\"/g" release_client_license.xml
	sed -i "s/hostName=\".*\"/hostName=\"$CLIENTIP\"/g" release_client_license.xml
	eval $CURLCMD -d @release_client_license.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //CVGui_GenericResp -o "Error code: " -v @errorCode -n
	
	## Rename client ##
	disp "Renaming client."
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" client_prop-retire.xml
	sed -i "s/<newName>.*<\/newName>/<newName>"$CLIENTNAME".retired<\/newName>/g" client_prop-retire.xml
	sed -i "s/<hostName>.*<\/hostName>/<hostName>"$CLIENTHOSTNAME".retired<\/hostName>/g" client_prop-retire.xml
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME".retired<\/clientName>/g" client_prop-retire_fallback.xml
	sed -i "s/<newName>.*<\/newName>/<newName>"$CLIENTNAME"<\/newName>/g" client_prop-retire_fallback.xml
	sed -i "s/<hostName>.*<\/hostName>/<hostName>"$CLIENTIP"<\/hostName>/g" client_prop-retire_fallback.xml
	eval $CURLCMD -d @client_prop-retire.xml -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

