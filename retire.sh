#!/bin/sh

## Set environment ##

DIR=$(dirname $0)
cd $DIR
source ./setenv.sh

## Client retirement ##

disp "Releasing client licenses."
sed -i "s/clientName=\".*\"/clientName=\"$CLIENTNAME\"/g" release_client_license.xml
sed -i "s/hostName=\".*\"/hostName=\"$CLIENTIP\"/g" release_client_license.xml
eval $CURLCMD -d @release_client_license.xml -L "$BASEURI/QCommand/qoperation%20execute" | xmlstarlet sel -t -m //CVGui_GenericResp -o "Error code: " -v @errorCode -n

