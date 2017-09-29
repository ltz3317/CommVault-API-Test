#!/bin/sh

eval $CURLCMD -L $BASEURI"/ClientGroup" | xmlstarlet sel -t -m "//groups[@name='"$CLIENTGROUPNAME"']" -v @Id -n
