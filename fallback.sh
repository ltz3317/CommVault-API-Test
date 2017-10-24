#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

## Get information ##

disp "Getting client ID by client name."
echo "Client Name: $CLIENTNAME"
if [ "$APPNAME" = "Virtual Server" ]
then
	export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
else
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
fi
echo "Client ID: $CLIENTID"

if [ "$APPNAME" != "Virtual Server" ]
then
	disp "Getting client group ID by client group name."
	echo "Client Group Name: $CLIENTGROUPNAME"
	export CLIENTGROUPID=$($DIR/get_clientgroupid_by_clientgroupname.sh)
	echo "Client Group ID: $CLIENTGROUPID"
fi

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Getting backupset by client ID."
	BACKUPSET=$($DIR/get_backupset_by_clientid.sh)
	BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
	BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
	echo "Backupset Name: $BACKUPSETNAME"
	echo "Backupset ID: $BACKUPSETID"
elif [ "$APPNAME" = "Virtual Server" ]
then
        ## Get backupset by client ID ##

	disp "Getting backupset by client ID."
        BACKUPSET=$($DIR/get_vsa_backupset_by_clientid.sh)
        BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
        BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
        echo "Backupset Name: $BACKUPSETNAME"
        echo "Backupset ID: $BACKUPSETID"
fi

disp "Getting subclient by client ID."
SUBCLIENT=$($DIR/get_subclient_by_clientid.sh)
SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
echo "Subclient Name: $SUBCLIENTNAME"
echo "Subclient ID: $SUBCLIENTID"

disp "Getting schedule policy ID by schedule policy name."
SCHEPID=$($DIR/get_schepid_by_schepname.sh)
echo "Schedule Policy ID: $SCHEPID"

## Remove subclient from schedule policy ##

disp "Removing schedule policy association"
curl -s -H $HEADER1 -H $HEADER3 -H "Authtoken:$TOKEN" -d "SubclientId=$SUBCLIENTID" -X DELETE -L $BASEURI"/Task/"$SCHEPID"/Entity" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n

## Fallback subclient ##

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Falling-back subclients properties for $APPNAME."
	eval $CURLCMD -d @- << BODY -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_UpdateSubClientPropertiesRequest>
	<newName>default</newName>
	<subClientProperties>
		<commonProperties>
			<storageDevice>
				<dataBackupStoragePolicy>
					<storagePolicyName>storp00</storagePolicyName>
				</dataBackupStoragePolicy>
			</storageDevice>
		</commonProperties>
	</subClientProperties>
</App_UpdateSubClientPropertiesRequest>
BODY

elif [ "$APPNAME" = "SQL Server" ]
then
	disp "Falling-back subclients properties for $APPNAME."
	XMLBODY="
<App_UpdateSubClientPropertiesRequest>
	<newName>default</newName>
	<subClientProperties>
		<commonProperties>
			<storageDevice>
				<dataBackupStoragePolicy>
					<storagePolicyName>storp00</storagePolicyName>
				</dataBackupStoragePolicy>
				<logBackupStoragePolicy>
					<storagePolicyName>storp00</storagePolicyName>
				</logBackupStoragePolicy>
			</storageDevice>
		</commonProperties>
			<contentOperationType>DELETE</contentOperationType>
	</subClientProperties>
</App_UpdateSubClientPropertiesRequest>
"
	for DB in $DATABASES
	do
		XMLBODY=$(echo "$XMLBODY" | sed "s/<\/subClientProperties>/<content><mssqlDbContent><databaseName>$DB<\/databaseName><\/mssqlDbContent><\/content><\/subClientProperties>/g")
	done
	eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Fallback backupset ##

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Falling-back backup set properties."
	eval $CURLCMD -d @- << BODY -L $BASEURI"/Backupset/$BACKUPSETID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_SetBackupsetPropertiesRequest>
  <backupsetProperties>
    <commonBackupSet>
      <newBackupSetName>defaultBackupSet</newBackupSetName>
    </commonBackupSet>
  </backupsetProperties>
</App_SetBackupsetPropertiesRequest>
BODY

elif [ "$APPNAME" = "MySQL" ]
then
	disp "Deleting MySQL instance."
	eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_DeleteInstanceRequest>
	<association>
		<entity>
			<clientName>$CLIENTNAME</clientName>
			<appName>MySQL</appName>
			<instanceName>$CLIENTNAME</instanceName>
		</entity>
	</association>
</App_DeleteInstanceRequest>
BODY

elif [ "$APPNAME" = "Virtual Server" ]
then
	disp "Deleting backupset for Virtual Server."
	eval $CURLCMD -X DELETE -L \"$BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Fallback user credential for MSSQL only ##

if [ "$APPNAME" = "SQL Server" ]
then
	disp "Falling-back $APPNAME user credential."
	eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_SetAgentPropertiesRequest>
	<agentProperties>
		<idaEntity>
			<appName>SQL Server</appName>
			<clientName>$CLIENTNAME</clientName>
		</idaEntity>
		<sql61Prop>
			<overrideHigherLevelSettings>
				<overrideGlobalAuthentication>false</overrideGlobalAuthentication>
				<useLocalSystemAccount>false</useLocalSystemAccount>
				<userAccount>
					<password>password</password>
					<userName>administrator</userName>
				</userAccount>
			</overrideHigherLevelSettings>
		</sql61Prop>
	</agentProperties>
	<association>
		<entity>
			<appName>SQL Server</appName>
			<clientName>$CLIENTNAME</clientName>
		</entity>
	</association>
</App_SetAgentPropertiesRequest>
BODY

fi

if [ "$APPNAME" != "Virtual Server" ]
then
	## Fallback client group ##

	disp "Falling-back client group properties."
	eval $CURLCMD -d @- << BODY -L "$BASEURI/ClientGroup/$CLIENTGROUPID" | xmlstarlet sel -t -m //App_GenericResp -o "Error code: " -v @errorCode -n

<App_PerformClientGroupReq>
	<clientGroupOperationType>Update</clientGroupOperationType>
	<clientGroupDetail>
		<associatedClientsOperationType>3</associatedClientsOperationType>
		<associatedClients>
			<clientName>$CLIENTNAME</clientName>
		</associatedClients>
		<clientGroup>
			<clientGroupName>$CLIENTGROUPNAME</clientGroupName>
		</clientGroup>
	</clientGroupDetail>
</App_PerformClientGroupReq>
BODY

	disp "Restarting client services."
        eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //EVGui_GenericResp -o "Error code: " -v @errorCode -n

<EVGui_ServiceControlRequest action="RESTART">
	<services allServices="true"/>
	<client clientName="$CLIENTNAME"/>
</EVGui_ServiceControlRequest>
BODY

	sleep 90	## Let the iDataAgent restart finishes. ##

	## Fallback client ##

	disp "Falling-back client properties."
	eval $CURLCMD -d @- << BODY -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

<App_SetClientPropertiesRequest>
	<clientProperties>
		<client>
			<clientEntity>
				<hostName>$CLIENTHOSTNAME</hostName>
			</clientEntity>
		</client>
		<clientProps>
			<dataInterfacePair active="true"></dataInterfacePair>
		</clientProps>
	</clientProperties>
</App_SetClientPropertiesRequest>
BODY

fi

disp "Logging out."
$DIR/logout.sh

