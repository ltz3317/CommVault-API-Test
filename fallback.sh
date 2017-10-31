#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

get_subclient_by_clientid()
{
	disp "Getting subclient by client ID."
	SUBCLIENT=$($DIR/get_subclient_by_clientid.sh)
	SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
	SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
	echo "Subclient Name: $SUBCLIENTNAME"
	echo "Subclient ID: $SUBCLIENTID"
}

get_schedulepolicyid_by_schedulepolicyname()
{
	disp "Getting schedule policy ID by schedule policy name."
	SCHEPID=$($DIR/get_schepid_by_schepname.sh)
	echo "Schedule Policy ID: $SCHEPID"
}

remove_subclient_from_schedulepolicy()
{
	disp "Removing schedule policy association"
	curl -s -H $HEADER1 -H $HEADER3 -H "Authtoken:$TOKEN" -d "SubclientId=$SUBCLIENTID" -X DELETE -L $BASEURI"/Task/"$SCHEPID"/Entity" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n
}

get_clientgroupid_by_clientgroupname()
{
	disp "Getting client group ID by client group name."
	echo "Client Group Name: $CLIENTGROUPNAME"
	export CLIENTGROUPID=$($DIR/get_clientgroupid_by_clientgroupname.sh)
	echo "Client Group ID: $CLIENTGROUPID"
}

fallback_clientgroup()
{
	disp "Falling-back client group properties."
	XMLBODY="
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
	"
	eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/ClientGroup/$CLIENTGROUPID" | xmlstarlet sel -t -m //App_GenericResp -o "Error code: " -v @errorCode -n

	disp "Restarting client services."
	XMLBODY="
		<EVGui_ServiceControlRequest>
			<action>RESTART</action>
			<services>
				<allServices>true</allServices>
			</services>
			<client>
				<clientName>$CLIENTNAME</clientName>
			</client>
		</EVGui_ServiceControlRequest>
	"
        eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //EVGui_GenericResp -o "Error code: " -v @errorCode -n

	sleep 90	## Let the iDataAgent restart finishes. ##
}

fallback_client()
{
	disp "Falling-back client properties."
	XMLBODY="
		<App_SetClientPropertiesRequest>
			<clientProperties>
				<client>
					<clientEntity>
						<hostName>$CLIENTHOSTNAME</hostName>
					</clientEntity>
				</client>
				<clientProps>
					<dataInterfacePair>
						<active>true</active>
					</dataInterfacePair>
				</clientProps>
			</clientProperties>
		</App_SetClientPropertiesRequest>
	"
	eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
}

disp "Getting client ID by client name."
echo "Client Name: $CLIENTNAME"

case "$APPNAME" in
	"Virtual Server")
		export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
		echo "Client ID: $CLIENTID"

		disp "Getting backupset by client ID."
	        BACKUPSET=$($DIR/get_vsa_backupset_by_clientid.sh)
	        BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
	        BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
	        echo "Backupset Name: $BACKUPSETNAME"
	        echo "Backupset ID: $BACKUPSETID"

		get_subclient_by_clientid
		get_schedulepolicyid_by_schedulepolicyname
		remove_subclient_from_schedulepolicy

		disp "Deleting backupset for Virtual Server."
		eval $CURLCMD -X DELETE -L \"$BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='"$VM"')"\" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
	;;
	"Windows File System"|"Linux File System")
		export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
		echo "Client ID: $CLIENTID"

		get_clientgroupid_by_clientgroupname

		disp "Getting backupset by client ID."
		BACKUPSET=$($DIR/get_backupset_by_clientid.sh)
		BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
		BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
		echo "Backupset Name: $BACKUPSETNAME"
		echo "Backupset ID: $BACKUPSETID"

		get_subclient_by_clientid
		get_schedulepolicyid_by_schedulepolicyname
		remove_subclient_from_schedulepolicy

		disp "Falling-back subclients properties for $APPNAME."
		XMLBODY="
			<App_UpdateSubClientPropertiesRequest>
				<newName>default</newName>
				<subClientProperties>
					<commonProperties>
						<storageDevice>
							<dataBackupStoragePolicy>
								<storagePolicyName>$OLDSTORAGEPOLICY</storagePolicyName>
							</dataBackupStoragePolicy>
						</storageDevice>
					</commonProperties>
				</subClientProperties>
			</App_UpdateSubClientPropertiesRequest>
		"
		eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

		disp "Falling-back backup set properties."
		XMLBODY="
			<App_SetBackupsetPropertiesRequest>
				<backupsetProperties>
					<commonBackupSet>
						<newBackupSetName>defaultBackupSet</newBackupSetName>
					</commonBackupSet>
				</backupsetProperties>
			</App_SetBackupsetPropertiesRequest>
		"
		eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Backupset/$BACKUPSETID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

		fallback_clientgroup
		fallback_client
	;;
	"SQL Server")
		export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
		echo "Client ID: $CLIENTID"

		get_clientgroupid_by_clientgroupname
		get_subclient_by_clientid
		get_schedulepolicyid_by_schedulepolicyname

		remove_subclient_from_schedulepolicy

		## Fallback subclient ##

		disp "Falling-back subclients properties for $APPNAME."
		XMLBODY="
			<App_UpdateSubClientPropertiesRequest>
				<newName>default</newName>
				<subClientProperties>
					<commonProperties>
						<storageDevice>
							<dataBackupStoragePolicy>
								<storagePolicyName>$OLDSTORAGEPOLICY</storagePolicyName>
							</dataBackupStoragePolicy>
							<logBackupStoragePolicy>
								<storagePolicyName>$OLDSTORAGEPOLICY</storagePolicyName>
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

		## Fallback user credential for MSSQL only ##

		disp "Falling-back $APPNAME user credential."
		XMLBODY="
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
		"
		eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

		fallback_clientgroup
		fallback_client
	;;
	"MySQL")
		export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
		echo "Client ID: $CLIENTID"

		get_clientgroupid_by_clientgroupname
		get_subclient_by_clientid
		get_schedulepolicyid_by_schedulepolicyname

		remove_subclient_from_schedulepolicy

		## Fallback backupset ##

		disp "Deleting MySQL instance."
		XMLBODY="
			<App_DeleteInstanceRequest>
				<association>
					<entity>
						<clientName>$CLIENTNAME</clientName>
						<appName>MySQL</appName>
						<instanceName>$CLIENTNAME</instanceName>
					</entity>
				</association>
			</App_DeleteInstanceRequest>
		"
		eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

		fallback_clientgroup
		fallback_client
	;;
esac

disp "Logging out."
$DIR/logout.sh

