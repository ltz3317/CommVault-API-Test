#!/bin/sh

curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H "Authtoken:$TOKEN" -L $BASEURI"/SchedulePolicy" | xmlstarlet sel -t -m "//taskDetail/task[@taskName='"$SCHEPNAME"']" -v @taskId
