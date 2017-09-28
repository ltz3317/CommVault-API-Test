#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
source $DIR/setenv.sh

## Client configuration ##

disp "Getting client ID by client name."
echo "Client Name: $CLIENTNAME"

if [ "$APPNAME" = "Virtual Server" ]
then
	export CLIENTID=$($DIR/get_vsa_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"
else
	export CLIENTID=$($DIR/get_clientid_by_clientname.sh)
	echo "Client ID: $CLIENTID"
	disp "Updating client_prop.xml and client_prop-fallbackup.xml."
	sed -i "s/<hostName>.*<\/hostName>/<hostName>"$CLIENTIP"<\/hostName>/" client_prop.xml
	sed -i "s/<SourceInterface ClientId=\".*\" Interface=\".*\"\/>/<SourceInterface ClientId=\""$CLIENTID"\" Interface=\""$CLIENTIP"\"\/>/" client_prop.xml
	sed -i "s/<hostName>.*<\/hostName>/<hostName>"$CLIENTNAME"<\/hostName>/" client_prop-fallback.xml
	 
	disp "Setting client properties."
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @client_prop.xml -L $BASEURI"/Client/$CLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Client Group configuration ##

if [ "$APPNAME" != "Virtual Server" ]
then
	disp "Getting client group ID by client group name."
	echo "Client Group Name: $CLIENTGROUPNAME"
	export CLIENTGROUPID=$($DIR/get_clientgroupid_by_clientgroupname.sh)
	echo "Client Group ID: $CLIENTGROUPID"
	disp "Updating clientgroup.xml and clientgroup-fallback.xml"
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/" clientgroup.xml clientgroup-fallback.xml
	sed -i "s/<clientGroupName>.*<\/clientGroupName>/<clientGroupName>"$CLIENTGROUPNAME"<\/clientGroupName>/" clientgroup.xml clientgroup-fallback.xml

	disp "Updating client group properties."
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @clientgroup.xml -L "$BASEURI/ClientGroup/$CLIENTGROUPID" | xmlstarlet sel -t -m //App_GenericResp -o "Error code: " -v @errorCode -n
fi

## MSSQL instance configuration ##

if [ "$APPNAME" = "SQL Server" ]
then
	disp "Setting user credential for $APPNAME."
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" mssql_user_credential.xml
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" mssql_user_credential-fallback.xml
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @mssql_user_credential.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Backupset configuration ##

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Getting backupset by client ID."
	BACKUPSET=$($DIR/get_backupset_by_clientid.sh)
	BACKUPSETNAME=$(echo $BACKUPSET | awk -F ':' '{print $1}')
	BACKUPSETID=$(echo $BACKUPSET | awk -F ':' '{print $2}')
	echo "Backupset Name: $BACKUPSETNAME"
	echo "Backupset ID: $BACKUPSETID"
	
	disp "Updating backupset-fallback.xml and backupset.xml."
	sed -i "s/<newBackupSetName>.*<\/newBackupSetName>/<newBackupSetName>"$BACKUPSETNAME"<\/newBackupSetName>/" backupset-fallback.xml
	sed -i "s/<newBackupSetName>.*<\/newBackupSetName>/<newBackupSetName>backupset-"$CLIENTNAME"<\/newBackupSetName>/" backupset.xml

	disp "Setting backup set properties."
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @backupset.xml -L $BASEURI"/Backupset/$BACKUPSETID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
	echo
elif [ "$APPNAME" = "MySQL" ]
then
	disp "Creating MySQL instance."
	sleep 5
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" mysql_instance.xml
	sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" mysql_instance-fallback.xml
	sed -i "s/<instanceName>.*<\/instanceName>/<instanceName>inst-"$CLIENTNAME"<\/instanceName>/g" mysql_instance.xml
	sed -i "s/<instanceName>.*<\/instanceName>/<instanceName>inst-"$CLIENTNAME"<\/instanceName>/g" mysql_instance-fallback.xml
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @mysql_instance.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "Virtual Server" ]
then
	disp "Creating backupset for Virtual Server. "
	sed -i "s/<backupsetName>.*<\/backupsetName>/<backupsetName>backupset-"$VM"<\/backupsetName>/g" backupset_vsa.xml
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @backupset_vsa.xml -L $BASEURI"/Backupset" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Subclient configuration ##

echo
echo "==============================="
echo "Getting subclient by client ID."
echo "==============================="
SUBCLIENT=$($DIR/get_subclient_by_clientid.sh)
SUBCLIENTNAME=$(echo $SUBCLIENT | awk -F ':' '{print $1}')
SUBCLIENTID=$(echo $SUBCLIENT | awk -F ':' '{print $2}')
echo "Subclient Name: $SUBCLIENTNAME"
echo "Subclient ID: $SUBCLIENTID"

if [ "$APPNAME" = "Windows File System" ] || [ "$APPNAME" = "Linux File System" ]
then
	disp "Updating subclient.xml and subclient-fallback.xml for $APPNAME."
	sed -i "s/<newName>.*<\/newName>/<newName>"$SUBCLIENTNAME"<\/newName>/" subclient-fallback.xml
	sed -i "s/<newName>.*<\/newName>/<newName>subclient-"$CLIENTNAME"<\/newName>/" subclient.xml

	disp "Setting subclient properties for $APPNAME."
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @subclient.xml -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "SQL Server" ]
then
	disp "Updating subclient_mssql.xml and subclient_mssql-fallback.xml for SQL Server."
	cp -p subclient_mssql.tpl subclient_mssql.xml
	cp -p subclient_mssql-fallback.tpl subclient_mssql-fallback.xml
	sed -i "s/<newName>.*<\/newName>/<newName>"$SUBCLIENTNAME"<\/newName>/" subclient_mssql-fallback.xml
	sed -i "s/<newName>.*<\/newName>/<newName>subclient-mssql-"$CLIENTNAME"<\/newName>/" subclient_mssql.xml
	for DB in $DATABASES
	do
		sed -i "s/<\/subClientProperties>/\t<content>\n\t\t<mssqlDbContent databaseName=\"$DB\"\/>\n\t\t<\/content>\n\t<\/subClientProperties>/g" subclient_mssql.xml subclient_mssql-fallback.xml
	done

	disp "Setting subclient properties for SQL Server."
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @subclient_mssql.xml -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "MySQL" ]
then
	disp "Updating subclient_mysql.xml and subclient_mysql-fallback.xml for MySQL."
	cp -p subclient_mysql.tpl subclient_mysql.xml
	sed -i "s/<newName>.*<\/newName>/<newName>subclient-mysql-"$CLIENTNAME"<\/newName>/" subclient_mysql.xml
	for DB in $DATABASES
	do
		sed -i "s/<\/subClientProperties>/\t<content>\n\t\t\t<mySQLContent>\n\t\t\t\t<databaseName>$DB<\/databaseName>\n\t\t\t<\/mySQLContent>\n\t\t<\/content>\n\t<\/subClientProperties>/g" subclient_mysql.xml
	done

	disp "Setting subclient properties for MySQL."
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @subclient_mysql.xml -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
elif [ "$APPNAME" = "Virtual Server" ]
then
	disp "Setting subclient properties for $APPNAME."
	sed -i "s/<newName>.*<\/newName>/<newName>subclient-"$VM"<\/newName>/g" subclient_vsa.xml
	sed -i "s/displayName=\".*\" equals/displayName=\""$VM"\" equals/g" subclient_vsa.xml
	curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -d @subclient_vsa.xml -L $BASEURI"/Subclient/$SUBCLIENTID" | xmlstarlet sel -t -m //response -o "Error code: " -v @errorCode -n
fi

## Schedule policy association ##

disp "Getting schedule policy ID by schedule policy name."
SCHEPID=$($DIR/get_schepid_by_schepname.sh)
echo "Schedule Policy ID: $SCHEPID"

disp "Adding schedule policy association"
curl -s -H $HEADER1 -H $HEADER3 -H "Authtoken:$TOKEN" -d "SubclientId=$SUBCLIENTID" -L $BASEURI"/Task/"$SCHEPID"/Entity/add" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n
echo

## Logout ##

disp "Logging out."
$DIR/logout.sh

