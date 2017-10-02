#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

## Client unretirement ##

disp "Reconfiguring client licenses."
sed -i "s/<clientName>.*<\/clientName>/<clientName>"$CLIENTNAME"<\/clientName>/g" reconfigure_client.xml
eval $CURLCMD -d @reconfigure_client.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //TMMsg_GenericResp -o "Error code: " -v @errorCode -n

