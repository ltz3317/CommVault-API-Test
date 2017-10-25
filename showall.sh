#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

get_client_info()
{
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	if [ -z "$CLIENTID" ]
	then
		export CLIENTNAME=$(eval $CURLCMD -L $BASEURI/Client | xmlstarlet sel -t -m "//clientEntity[starts-with(@clientName, '$CLIENTNAME.201')]" -v @clientName -n)
		echo "Client Name: $CLIENTNAME"
		export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	fi
	echo "Client Name: $CLIENTNAME"
	echo "Client ID: $CLIENTID"

	CURLOUT=$(eval $CURLCMD -L $BASEURI"/Client/$CLIENTID")
	echo $CURLOUT | xmlstarlet sel -t -m //dataInterfacePair -o "DIP Active: " -v @active -n -m SourceInterface -o "SourceInterface Client ID: " -v @ClientId -n -o "Interface: " -v @Interface -n -m ../DestInterface -o "DestInterface Client ID: " -v @ClientId -n -o "Interface: " -v @Interface -n
	echo $CURLOUT | xmlstarlet sel -t -m //clientEntity -o "clientEntity hostName: " -v @hostName -n
	echo $CURLOUT | xmlstarlet sel -t -m //ActivePhysicalNode -o "ActivePhysicalNode hostName: " -v @hostName -n
}

get_clientgroup_info()
{
	echo "Client Group Name: $CLIENTGROUPNAME"
	export CLIENTGROUPID=$($DIR/get_clientgroupid_by_clientgroupname.sh)
	echo "Client Group ID: $CLIENTGROUPID"
	eval $CURLCMD -L $BASEURI"/ClientGroup/$CLIENTGROUPID" | xmlstarlet sel -t -m "//associatedClients[@clientName='"$CLIENTNAME"']" -o "Associated Client Name: " -v @clientName -n
}

case "$APPNAME" in
	"Virtual Server")
		## Get client information ##

		echo "Client Name: $CLIENTNAME"
        	export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
		echo "Client ID: $CLIENTID"

		## Get backupset by client ID ##
	
		BACKUPSET=$($DIR/get_vsa_backupset_by_clientid.sh)
		if [ -z "$BACKUPSET" ]
		then
			BACKUPSET=$(eval $CURLCMD -L $BASEURI"/Backupset?clientId=$CLIENTID" | xmlstarlet sel -t -m "//backupSetEntity[starts-with(@backupsetName, '$VM.201')]" -v @backupsetName -o ":" -v @backupsetId)
		fi
		BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
		BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
		echo "Backupset Name: $BACKUPSETNAME"
		echo "Backupset ID: $BACKUPSETID"

		## Get subclient information ##

		SUBCLIENT=$(eval $CURLCMD -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and @backupsetName='$VM']" -v @subclientName -o ":"  -v @subclientId)
		if [ -z "$SUBCLIENT" ]
		then
			SUBCLIENT=$(eval $CURLCMD -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and @backupsetName='$BACKUPSETNAME']" -v @subclientName -o ":"  -v @subclientId)
			SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
			SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
		fi
		echo "Subclient Name: $SUBCLIENTNAME"
		echo "Subclient ID: $SUBCLIENTID"
		if [ ! -z "$SUBCLIENTID" ]
		then
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //dataBackupStoragePolicy -o "Data Storage policy name: " -v @storagePolicyName -n
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //children -o "VM: " -v @displayName -n
		fi

		## Get schedule policy ID by schedule policy name ##
		
		SCHEPID=$($DIR/get_schepid_by_schepname.sh)
		echo "Schedule Policy ID: $SCHEPID"
		
		## Getting schedule policy associations ##
		
		eval $CURLCMD -L $BASEURI"/SchedulePolicy/$SCHEPID" | xmlstarlet sel -t -m "//associations[@subclientId='"$SUBCLIENTID"']" -o "Associated Subclient Name: " -v @subclientName -o ", Subclient ID: " -v @subclientId -n
	;;
	"MySQL")
		## Get client information ##
		get_client_info

		## Get client group information ##
		get_clientgroup_info

		## Get MySQL instance properties ##
		XMLBODY="
			<App_GetInstancePropertiesRequest>
				<association>
					<entity>	
						<clientName>$CLIENTNAME</clientName>
						<appName>MySQL</appName> 
						<instanceName>$CLIENTNAME</instanceName>
					</entity>
				</association>
			</App_GetInstancePropertiesRequest>
		"
		eval $CURLCMD -d \"$XMLBODY\" -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //instanceProperties -c instance -n -c mySqlInstance -n -c mysqlStorageDevice -n

		## Get subclient information ##

		SUBCLIENT=$(eval $CURLCMD -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and not(@subclientName='(command line)')]" -v @subclientName -o ":"  -v @subclientId)
		SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
                SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
                echo "Subclient Name: $SUBCLIENTNAME"
                echo "Subclient ID: $SUBCLIENTID"
		if [ ! -z "$SUBCLIENTID" ]
		then
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //dataBackupStoragePolicy -o "Data Storage policy name: " -v @storagePolicyName -n
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //logBackupStoragePolicy -o "Log Storage policy name: " -v @storagePolicyName -n -m //mySQLContent -o "Database: " -v @databaseName -n
		fi

		## Get schedule policy ID by schedule policy name ##
		
		SCHEPID=$($DIR/get_schepid_by_schepname.sh)
		echo "Schedule Policy ID: $SCHEPID"
		
		## Getting schedule policy associations ##
		
		eval $CURLCMD -L $BASEURI"/SchedulePolicy/$SCHEPID" | xmlstarlet sel -t -m "//associations[@subclientId='"$SUBCLIENTID"']" -o "Associated Subclient Name: " -v @subclientName -o ", Subclient ID: " -v @subclientId -n

		## Checking if the client is retired ##

		eval $CURLCMD -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m "//clientProps" -o "IsDeletedClient: " -v @IsDeletedClient -n
	;;
	"SQL Server")
		## Get client information ##
		get_client_info

		## Get client group information ##
		get_clientgroup_info

		## Get subclient information ##
		
		SUBCLIENT=$(eval $CURLCMD -L $BASEURI"/subclient?clientId=$CLIENTID" | xmlstarlet sel -t -m "//subClientEntity[@appName='$APPNAME' and not(@subclientName='(command line)')]" -v @subclientName -o ":"  -v @subclientId)
		SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
		SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
		echo "Subclient Name: $SUBCLIENTNAME"
		echo "Subclient ID: $SUBCLIENTID"
		if [ ! -z "$SUBCLIENTID" ]
		then
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //dataBackupStoragePolicy -o "Data Storage policy name: " -v @storagePolicyName -n
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //logBackupStoragePolicy -o "Log Storage policy name: " -v @storagePolicyName -n -m //mssqlDbContent -o "DB Name: " -v @databaseName -n
		fi

		## Get schedule policy ID by schedule policy name ##
		
		SCHEPID=$($DIR/get_schepid_by_schepname.sh)
		echo "Schedule Policy ID: $SCHEPID"
		
		## Getting schedule policy associations ##
		
		eval $CURLCMD -L $BASEURI"/SchedulePolicy/$SCHEPID" | xmlstarlet sel -t -m "//associations[@subclientId='"$SUBCLIENTID"']" -o "Associated Subclient Name: " -v @subclientName -o ", Subclient ID: " -v @subclientId -n

		## Checking if the client is retired ##

		eval $CURLCMD -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m "//clientProps" -o "IsDeletedClient: " -v @IsDeletedClient -n
	;;
	"Windows File System"|"Linux File System")
		## Get client information ##
		get_client_info

		## Get client group information ##
		get_clientgroup_info

		## Get backupset information ##

		BACKUPSET=$($DIR/get_backupset_by_clientid.sh)
		BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
		BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
		echo "Backupset Name: $BACKUPSETNAME"
		echo "Backupset ID: $BACKUPSETID"

		## Get subclient information ##
		
		SUBCLIENT=$($DIR/get_subclient_by_clientid.sh)
		SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
		SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
		echo "Subclient Name: $SUBCLIENTNAME"
		echo "Subclient ID: $SUBCLIENTID"
		if [ ! -z "$SUBCLIENTID" ]
		then
			eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //dataBackupStoragePolicy -o "Data Storage policy name: " -v @storagePolicyName -n
		fi

		## Get schedule policy ID by schedule policy name ##
		
		SCHEPID=$($DIR/get_schepid_by_schepname.sh)
		echo "Schedule Policy ID: $SCHEPID"
		
		## Getting schedule policy associations ##
		
		eval $CURLCMD -L $BASEURI"/SchedulePolicy/$SCHEPID" | xmlstarlet sel -t -m "//associations[@subclientId='"$SUBCLIENTID"']" -o "Associated Subclient Name: " -v @subclientName -o ", Subclient ID: " -v @subclientId -n

		## Checking if the client is retired ##

		eval $CURLCMD -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m "//clientProps" -o "IsDeletedClient: " -v @IsDeletedClient -n
	;;
esac

## Logout ##

$DIR/logout.sh

