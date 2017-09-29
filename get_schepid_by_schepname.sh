#!/bin/sh

eval $CURLCMD -L $BASEURI"/SchedulePolicy" | xmlstarlet sel -t -m "//taskDetail/task[@taskName='"$SCHEPNAME"']" -v @taskId
