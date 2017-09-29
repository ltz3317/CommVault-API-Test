#!/bin/sh

eval $CURLCMD -L \"$BASEURI"/Client/byName(clientName='"$CLIENTNAME"')"\" | xmlstarlet sel -t -m //clientEntity -v @clientId -n
