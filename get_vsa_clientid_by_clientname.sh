#!/bin/sh

curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/Client/VMPseudoClient" | xmlstarlet sel -t -m "//client[@clientName='"$CLIENTNAME"']" -v @clientId -n
