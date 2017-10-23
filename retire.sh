#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

TS=`date +%Y%m%d.%H%M`

if [ "$APPNAME" = "Virtual Server" ]
then
	## Rename backupset ##

	disp "Renaming backupset for $APPNAME".
	eval $CURLCMD -d @- << BODY -L \"$BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_SetBackupsetPropertiesRequest>
	<association>
		<entity>
			<appName>Virtual Server</appName>
			<backupsetName>$VM</backupsetName>
			<clientName>10.60.19.16</clientName>
			<instanceName>VMware</instanceName>
		</entity>
	</association>
	<backupsetProperties>
		<commonBackupSet>
			<newBackupSetName>$VM.$TS</newBackupSetName>
		</commonBackupSet>
	</backupsetProperties>
</App_SetBackupsetPropertiesRequest>
BODY

	## Retire subclient ##

	disp "Retiring subclient for $APPNAME".
	eval $CURLCMD -d @- << BODY -L \"$BASEURI"/Subclient/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM.$TS"',subclientName='"$VM"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_UpdateSubClientPropertiesRequest>
	<association>
		<entity>
			<appName>Virtual Server</appName>
			<backupsetName>$VM.retired</backupsetName>
			<clientName>10.60.19.16</clientName>
			<instanceName>VMware</instanceName>
			<subclientName>$VM</subclientName>
		</entity>
	</association>
	<newName>$VM.$TS</newName>
	<subClientProperties>
		<commonProperties>
			<enableBackup>false</enableBackup>
		</commonProperties>
	</subClientProperties>
</App_UpdateSubClientPropertiesRequest>
BODY

else
	## Get client information ##
	
	disp "Getting client ID by client name."
	echo "Client Name: $CLIENTNAME"
	
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"
	
	## Release client licenses ##
	
	disp "Releasing client licenses."
	eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //CVGui_GenericResp -o "Error code: " -v @errorCode -n

<TMMsg_ReleaseLicenseReq isClientLevelOperation="1">
	<clientEntity _type_="CLIENT_ENTITY" clientName="$CLIENTNAME"/>
	<licenseTypes appType="0" licenseType="0" licenseName=""/>
</TMMsg_ReleaseLicenseReq>
BODY
	
	## Rename client ##
	disp "Renaming client."
	eval $CURLCMD -d @- << BODY -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_SetClientPropertiesRequest>
	<association>
		<entity>
			<clientName>$CLIENTNAME</clientName>
			<newName>$CLIENTNAME.$TS</newName>
		</entity>
	</association>
	<clientProperties>
		<client>
			<clientEntity>
				<hostName>$CLIENTHOSTNAME.$TS</hostName>
    	 		</clientEntity>
		</client>
	</clientProperties>
</App_SetClientPropertiesRequest>
BODY

fi

## Logout ##

$DIR/logout.sh

