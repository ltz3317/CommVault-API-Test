#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

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

