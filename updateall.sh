#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

configure_client()
{
	## Client configuration ##
	
	disp "Getting client ID by client name."
	echo "Client Name: $CLIENTNAME"

	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"

	disp "Setting client properties."
	XMLBODY="
		<App_SetClientPropertiesRequest>
			<clientProperties>
				<client>
					<clientEntity>
						<hostName>$CLIENTIP</hostName>
					</clientEntity>
				</client>
				<clientProps>
					<dataInterfacePair>
						<active>true</active>
						<DestInterface>
							<ClientId>$MACLIENTID1</ClientId>
							<Interface>$MAIP1</Interface>
						</DestInterface>
						<SourceInterface>
							<ClientId>$CLIENTID</ClientId>
							<Interface>$CLIENTIP</Interface>
						</SourceInterface>
					</dataInterfacePair>
					<dataInterfacePair>
						<active>true</active>
						<DestInterface>
							<ClientId>$MACLIENTID2</ClientId>
							<Interface>$MAIP2</Interface>
						</DestInterface>
						<SourceInterface>
							<ClientId>$CLIENTID</ClientId>
							<Interface>$CLIENTIP</Interface>
						</SourceInterface>
					</dataInterfacePair>
				</clientProps>
			</clientProperties>
		</App_SetClientPropertiesRequest>
	"
	eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
}

configure_clientgroup()
{
	## Client Group configuration ##

	disp "Getting client group ID by client group name."
	echo "Client Group Name: $CLIENTGROUPNAME"
	export CLIENTGROUPID=$($DIR/get_clientgroupid_by_clientgroupname.sh)
	echo "Client Group ID: $CLIENTGROUPID"

	disp "Updating client group properties."
	## eval $CURLCMD -d @- << BODY -L "$BASEURI/ClientGroup/$CLIENTGROUPID" | xmlstarlet sel -t -m //App_GenericResp -o "Error code: " -v @errorCode -n
	XMLBODY="
		<App_PerformClientGroupReq>
			<clientGroupOperationType>Update</clientGroupOperationType>
			<clientGroupDetail>
				<associatedClientsOperationType>2</associatedClientsOperationType>
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

# 	disp "Restarting client services."
# 	eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //EVGui_GenericResp -o "Error code: " -v @errorCode -n
# 
# <EVGui_ServiceControlRequest action="RESTART">
# 	<services allServices="true"/>
# 	<client clientName="$CLIENTNAME"/>
# </EVGui_ServiceControlRequest>
# BODY
# 
# 	sleep 60	## Let the iDataAgent restart finishes. ##
	disp "Pushing firewall configuration."
	XMLBODY="
		<App_PushFirewallConfigurationRequest>
			<entity>
				<clientName>$CLIENTNAME</clientName>
				<clientGroupName>$CLIENTGROUPNAME</clientGroupName>
			</entity>
		</App_PushFirewallConfigurationRequest>
	"
	eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //entityResponse -o "Error code: " -v @errorCode -n
}

get_subclient_by_clientid()
{
	echo
	echo "==============================="
	echo "Getting subclient by client ID."
	echo "==============================="
	SUBCLIENT=$($DIR/get_subclient_by_clientid.sh)
	SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
	SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
	echo "Subclient Name: $SUBCLIENTNAME"
	echo "Subclient ID: $SUBCLIENTID"
}

configure_fs_backupset()
{
	## FS backupset configuration ##

	disp "Getting backupset by client ID."
	BACKUPSET=$($DIR/get_backupset_by_clientid.sh)
	BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
	BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
	echo "Backupset Name: $BACKUPSETNAME"
	echo "Backupset ID: $BACKUPSETID"

	disp "Setting backup set properties."
	XMLBODY="
		<App_SetBackupsetPropertiesRequest>
			<backupsetProperties>
				<commonBackupSet>
					<newBackupSetName>$CLIENTNAME</newBackupSetName>
				</commonBackupSet>
			</backupsetProperties>
		</App_SetBackupsetPropertiesRequest>
	"
	eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Backupset/$BACKUPSETID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
}

configure_fs_subclient()
{
	## FS subclient configuration ##

	get_subclient_by_clientid
	disp "Setting subclient properties for $APPNAME."
	## eval $CURLCMD -d @- << BODY -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

	XMLBODY="
		<App_UpdateSubClientPropertiesRequest>
			<newName>$CLIENTNAME</newName>
			<subClientProperties>
				<commonProperties>
					<storageDevice>
						<dataBackupStoragePolicy>
	 						<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
						</dataBackupStoragePolicy>
					</storageDevice>
				</commonProperties>
			</subClientProperties>
		</App_UpdateSubClientPropertiesRequest>
	"
	eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
}

case "$APPNAME" in
	"MySQL")
		configure_client
		configure_clientgroup

		disp "Creating MySQL instance."
		XMLBODY="
			<App_CreateInstanceRequest>
			<instanceProperties>
					<instance>
						<clientName>$CLIENTNAME</clientName>
						<appName>MySQL</appName>
						<instanceName>$CLIENTNAME</instanceName>
					</instance>
					<security>
						<associatedUserGroups>
							<userGroupName/>
						</associatedUserGroups>
						<associatedUserGroupsOperationType>ADD</associatedUserGroupsOperationType>
					</security>
					<mySqlInstance>
						<BinaryDirectory>$BINDIR</BinaryDirectory>
						<LogDataDirectory>$LOGDIR</LogDataDirectory>
						<ConfigFile>$CONFIGFILE</ConfigFile>
						<port>$SOCKET</port>
						<EnableAutoDiscovery/>
						<SAUser>
							<userName>$SAUSER</userName>
							<password>$SAPASSWORD</password>
						</SAUser>
						<unixUser>
							<userName>$UNIXUSER</userName>
						</unixUser>
						<mysqlStorageDevice>
							<logBackupStoragePolicy>
								<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
							</logBackupStoragePolicy>
							<commandLineStoragePolicy>
								<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
							</commandLineStoragePolicy>
						</mysqlStorageDevice>
					</mySqlInstance>          
				</instanceProperties>
			</App_CreateInstanceRequest>
		"
		## eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
		COUNT=1
		while [ "$EC" != "0" ] && [ "$COUNT" -lt 101 ]
		do
			echo "Attempt: $COUNT"
			EC=$(eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -v @errorCode)
			echo "Error code: $EC"
			COUNT=$(expr "$COUNT" + 1)
		done

		## Subclient configuration ##

		get_subclient_by_clientid
		XMLBODY="
			<App_UpdateSubClientPropertiesRequest>
				<newName>$CLIENTNAME</newName>
				<subClientProperties>
					<contentOperationType>ADD</contentOperationType>
					<commonProperties>
						<storageDevice>
							<dataBackupStoragePolicy>
								<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
							</dataBackupStoragePolicy>
						</storageDevice>
					</commonProperties>
				</subClientProperties>
			</App_UpdateSubClientPropertiesRequest>
		"
		for DB in $DATABASES
		do
			XMLBODY=$(echo "$XMLBODY" | sed "s/<\/subClientProperties>/\t<content>\n\t\t\t<mySQLContent>\n\t\t\t\t<databaseName>$DB<\/databaseName>\n\t\t\t<\/mySQLContent>\n\t\t<\/content>\n\t<\/subClientProperties>/g")
		done

		disp "Setting subclient properties for MySQL."
		eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
	;;
	"SQL Server")
		configure_client
		configure_clientgroup

		## MSSQL instance configuration ##
		
		disp "Setting user credential for $APPNAME."
		XMLBODY="
			<App_SetAgentPropertiesRequest>
				<agentProperties>
					<idaEntity>
						<appName>SQL Server</appName>
						<clientName>$CLIENTNAME</clientName>
					</idaEntity>
					<sql61Prop>
						<overrideHigherLevelSettings>
							<overrideGlobalAuthentication>true</overrideGlobalAuthentication>
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

		## Subclient configuration ##

		get_subclient_by_clientid
		XMLBODY="
			<App_UpdateSubClientPropertiesRequest>
				<newName>$CLIENTNAME</newName>
				<subClientProperties>
					<commonProperties>
						<storageDevice>
							<dataBackupStoragePolicy>
								<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
							</dataBackupStoragePolicy>
							<logBackupStoragePolicy>
								<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
							</logBackupStoragePolicy>
						</storageDevice>
					</commonProperties>
					<contentOperationType>ADD</contentOperationType>
				</subClientProperties>
			</App_UpdateSubClientPropertiesRequest>
		"
	
		for DB in $DATABASES
		do
			XMLBODY=$(echo "$XMLBODY" | sed "s/<\/subClientProperties>/<content><mssqlDbContent><databaseName>$DB<\/databaseName><\/mssqlDbContent><\/content><\/subClientProperties>/g")
		done
	
		disp "Setting subclient properties for SQL Server."
		eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
	;;
	"Windows File System"|"Linux File System")
		configure_client
		configure_clientgroup
		configure_fs_backupset
		configure_fs_subclient
	;;
	"Virtual Server")
		disp "Getting client ID by client name."
		echo "Client Name: $CLIENTNAME"
		export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
		echo "Client ID: $CLIENTID"

		## Backupset configuration ##

		disp "Creating backupset for Virtual Server. "
		## eval $CURLCMD -d @- << BODY -L $BASEURI"/Backupset" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
		XMLBODY="
			<App_CreateBackupSetRequest>
				<association>
					<entity>
						<appName>Virtual Server</appName>
						<backupsetName>$VM</backupsetName>
						<clientName>$CLIENTNAME</clientName>
						<instanceName>VMware</instanceName>
					</entity>
				</association>
			</App_CreateBackupSetRequest>
		"
		eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Backupset" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n

		## Subclient configuration ##

		get_subclient_by_clientid
		disp "Setting subclient properties for $APPNAME."
		XMLBODY="
			<App_UpdateSubClientPropertiesRequest>
				<newName>$VM</newName>
				<subClientProperties>
					<vmContentOperationType>OVERWRITE</vmContentOperationType>
					<commonProperties>
						<enableBackup>true</enableBackup>
						<storageDevice>
							<dataBackupStoragePolicy>
								<storagePolicyName>$STORAGEPOLICY</storagePolicyName>
							</dataBackupStoragePolicy>
						</storageDevice>
					</commonProperties>
					<vmContent>
						<children>
							<type>VMName</type>
							<displayName>$VM</displayName>
							<equalsOrNotEquals>1</equalsOrNotEquals>
						</children>
					</vmContent>
				</subClientProperties>
			</App_UpdateSubClientPropertiesRequest>
		"
		eval $CURLCMD -d \"$XMLBODY\" -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
	;;
esac

## Schedule policy association ##

disp "Getting schedule policy ID by schedule policy name."
SCHEPID=$($DIR/get_schepid_by_schepname.sh)
echo "Schedule Policy ID: $SCHEPID"

disp "Adding schedule policy association"
curl -s -H $HEADER1 -H $HEADER3 -H "Authtoken:$TOKEN" -d "SubclientId=$SUBCLIENTID" -L $BASEURI"/Task/"$SCHEPID"/Entity/add" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n

## Logout ##

disp "Logging out."
$DIR/logout.sh

