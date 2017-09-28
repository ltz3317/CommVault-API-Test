#!/bin/sh

curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/Client/byName(clientName='"$CLIENTNAME"')" | xmlstarlet sel -t -m //clientEntity -v @clientId -n
