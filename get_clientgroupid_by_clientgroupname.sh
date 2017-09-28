#!/bin/sh

curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/ClientGroup" | xmlstarlet sel -t -m "//groups[@name='"$CLIENTGROUPNAME"']" -v @Id -n
