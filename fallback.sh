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
echo

## Fallback subclient ##

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Falling-back subclients properties for $APPNAME."
	eval $CURLCMD -d @subclient-fallback.xml -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "SQL Server" ]
then
	disp "Falling-back subclients properties for $APPNAME."
	eval $CURLCMD -d @subclient_mssql-fallback.xml -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Fallback backupset ##

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Falling-back backup set properties."
	eval $CURLCMD -d @backupset-fallback.xml -L $BASEURI"/Backupset/$BACKUPSETID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "MySQL" ]
then
	disp "Deleting MySQL instance."
	eval $CURLCMD -d @mysql_instance-fallback.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "Virtual Server" ]
then
	disp "Deleting backupset for Virtual Server."
	eval $CURLCMD -X DELETE -L $BASEURI"/Backupset/byName(clientName='"$CLIENTNAME"',appName='Virtual%20Server',backupsetName='backupset-"$VM"')" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Fallback user credential for MSSQL only ##

if [ "$APPNAME" = "SQL Server" ]
then
	disp "Falling-back $APPNAME user credential."
	eval $CURLCMD -d @mssql_user_credential-fallback.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

if [ "$APPNAME" != "Virtual Server" ]
then
	## Fallback client group ##

	disp "Falling-back client group properties."
	eval $CURLCMD -d @clientgroup-fallback.xml -L "$BASEURI/ClientGroup/$CLIENTGROUPID" | xmlstarlet sel -t -m //App_GenericResp -o "Error code: " -v @errorCode -n

	## Fallback client ##

	disp "Falling-back client properties."
	eval $CURLCMD -d @client_prop-fallback.xml -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

disp "Logging out."
$DIR/logout.sh

