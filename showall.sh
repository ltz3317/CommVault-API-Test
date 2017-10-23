#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

## Get client information ##

echo "Client Name: $CLIENTNAME"
if [ "$APPNAME" = "Virtual Server" ]
then
	export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
else
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
fi
echo "Client ID: $CLIENTID"

CURLOUT=$(eval $CURLCMD -L $BASEURI"/Client/$CLIENTID")
echo $CURLOUT | xmlstarlet sel -t -m //dataInterfacePair -o "DIP Active: " -v @active -n -m SourceInterface -o "SourceInterface Client ID: " -v @ClientId -n -o "Interface: " -v @Interface -n -m ../DestInterface -o "DestInterface Client ID: " -v @ClientId -n -o "Interface: " -v @Interface -n
echo $CURLOUT | xmlstarlet sel -t -m //clientEntity -o "clientEntity hostName: " -v @hostName -n
echo $CURLOUT | xmlstarlet sel -t -m //ActivePhysicalNode -o "ActivePhysicalNode hostName: " -v @hostName -n

## Get client group information ##

if [ "$APPNAME" != "Virtual Server" ]
then
	echo "Client Group Name: $CLIENTGROUPNAME"
	export CLIENTGROUPID=$($DIR/get_clientgroupid_by_clientgroupname.sh)
	echo "Client Group ID: $CLIENTGROUPID"
	## eval $CURLCMD -L $BASEURI"/ClientGroup/7" | xmlstarlet sel -t -m "//associatedClients[@clientName='esdc10rhl005poc']" -o "Associated Client Name: " -v @clientName -n
	eval $CURLCMD -L $BASEURI"/ClientGroup/7" | xmlstarlet sel -t -m "//associatedClients[@clientName='"$CLIENTNAME"']" -o "Associated Client Name: " -v @clientName -n
fi

## Get backupset information ##

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	## Get backupset by client ID ##
	
	BACKUPSET=$($DIR/get_backupset_by_clientid.sh)
	BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
	BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
	echo "Backupset Name: $BACKUPSETNAME"
	echo "Backupset ID: $BACKUPSETID"
elif [ "$APPNAME" = "Virtual Server" ]
then
	## Get backupset by client ID ##

	BACKUPSET=$($DIR/get_vsa_backupset_by_clientid.sh)
	BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
	BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
	echo "Backupset Name: $BACKUPSETNAME"
	echo "Backupset ID: $BACKUPSETID"
elif [ "$APPNAME" = "MySQL" ]
then
	## Get MySQL instance properties ##

	eval $CURLCMD -d @- << BODY -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //instanceProperties -c instance -n -c mySqlInstance -n -c mysqlStorageDevice -n

<App_GetInstancePropertiesRequest>
	<association>
		<entity>	
			<clientName>$CLIENTNAME</clientName>
			<appName>MySQL</appName> 
			<instanceName>$CLIENTNAME</instanceName>
		</entity>
	</association>
</App_GetInstancePropertiesRequest>
BODY

fi

## Get subclient information ##

SUBCLIENT=$($DIR/get_subclient_by_clientid.sh)
SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
echo "Subclient Name: $SUBCLIENTNAME"
echo "Subclient ID: $SUBCLIENTID"
if [ ! -z "$SUBCLIENTID" ]
then
	eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //dataBackupStoragePolicy -o "Data Storage policy name: " -v @storagePolicyName -n
	
	if [ "$APPNAME" = "SQL Server" ]
	then
		eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //logBackupStoragePolicy -o "Log Storage policy name: " -v @storagePolicyName -n -m //mssqlDbContent -o "DB Name: " -v @databaseName -n
	elif [ "$APPNAME" = "MySQL" ]
	then
		eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //logBackupStoragePolicy -o "Log Storage policy name: " -v @storagePolicyName -n -m //mySQLContent -o "Database: " -v @databaseName -n
	elif [ "$APPNAME" = "Virtual Server" ]
	then
		eval $CURLCMD -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //children -o "VM: " -v @displayName -n
	fi
fi

## Get schedule policy ID by schedule policy name ##

SCHEPID=$($DIR/get_schepid_by_schepname.sh)
echo "Schedule Policy ID: $SCHEPID"

## Getting schedule policy associations ##

eval $CURLCMD -L $BASEURI"/SchedulePolicy/$SCHEPID" | xmlstarlet sel -t -m "//associations[@subclientId='"$SUBCLIENTID"']" -o "Associated Subclient Name: " -v @subclientName -o ", Subclient ID: " -v @subclientId -n

## Checking if the client is retired ##

eval $CURLCMD -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m "//clientProps" -o "IsDeletedClient: " -v @IsDeletedClient -n

## Logout ##

$DIR/logout.sh

