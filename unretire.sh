#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

if [ "$APPNAME" = "Virtual Server" ]
then
	disp "Getting client ID by client name."
	echo "Client Name: $CLIENTNAME"
	export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
        echo "Client ID: $CLIENTID"

	## Fallback subclient ##

	disp "Falling back subclient for $APPNAME."
	BACKUPSETNAME=$(eval $CURLCMD -L $BASEURI/Backupset?clientId=$CLIENTID | xmlstarlet sel -t -m "//backupSetEntity[starts-with(@backupsetName, '$VM.201')]" -v @backupsetName)
	SUBCLIENTNAME=$(eval $CURLCMD -L $BASEURI/Subclient?clientId=$CLIENTID | xmlstarlet sel -t -m "//subClientEntity[starts-with(@subclientName, '$VM.201')]" -v @subclientName)
	eval $CURLCMD -d @- << BODY -L \"$BASEURI"/Subclient/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$BACKUPSETNAME"',subclientName='"$SUBCLIENTNAME"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_UpdateSubClientPropertiesRequest>
	<association>
		<entity>
			<appName>Virtual Server</appName>
			<backupsetName>$BACKUPSETNAME</backupsetName>
			<clientName>$CLIENTNAME</clientName>
			<instanceName>VMware</instanceName>
			<subclientName>$SUBCLIENTNAME</subclientName>
		</entity>
	</association>
	<newName>$VM</newName>
	<subClientProperties>
		<commonProperties>
			<enableBackup>true</enableBackup>
		</commonProperties>
	</subClientProperties>
</App_UpdateSubClientPropertiesRequest>
BODY

	## Fallback backupset name ##

	disp "Falling back backupset name for $APPNAME."
        eval $CURLCMD -d @- << BODY -L \"$BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$BACKUPSETNAME"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_SetBackupsetPropertiesRequest>
	<association>
		<entity>
			<appName>Virtual Server</appName>
			<backupsetName>$BACKUPSETNAME</backupsetName>
			<clientName>$CLIENTNAME</clientName>
			<instanceName>VMware</instanceName>
		</entity>
	</association>
	<backupsetProperties>
		<commonBackupSet>
			<newBackupSetName>$VM</newBackupSetName>
		</commonBackupSet>
	</backupsetProperties>
</App_SetBackupsetPropertiesRequest>
BODY

else
	## Get client information ##
	
	disp "Getting client ID by client name."
	ORICLIENTNAME=$CLIENTNAME
	## export CLIENTNAME=$CLIENTNAME.retired
	export CLIENTNAME=$(eval $CURLCMD -L $BASEURI/Client | xmlstarlet sel -t -m "//clientEntity[starts-with(@clientName, '$CLIENTNAME.201')]" -v @clientName)
	echo "Client Name: $CLIENTNAME"
	
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"
	
	## Fallback client name and host name ##
	disp "Falling back client name and host name."

	## Have to rollback in GUI, coz retired hostname is unreachable. ##
	echo "Please change the host name of the $CLIENTNAME to $CLIENTIP,"
	read -p "and client name to $ORICLIENTNAME in CommCell Console. Press Enter to continue."

	## Reconfigure client licenses ##
	
	disp "Reconfiguring client licenses."
	eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n

<TMMsg_ClientReconfigurationReq>
	<clientInfo>
		<clientName>$ORICLIENTNAME</clientName>
	</clientInfo>
	<appTypes>
		<appName/>
	</appTypes>
</TMMsg_ClientReconfigurationReq>
BODY

fi

## Logout ##

$DIR/logout.sh

