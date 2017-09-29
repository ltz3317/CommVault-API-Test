#!/bin/sh

eval $CURLCMD -L $BASEURI"/Client/VMPseudoClient" | xmlstarlet sel -t -m "//client[@clientName='"$CLIENTNAME"']" -v @clientId -n
