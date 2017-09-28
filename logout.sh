#!/bin/sh

curl -s -H $HEADER1 -H $HEADER3 -H "Content-Length:0" -H "Authtoken:$TOKEN" -L -X POST $BASEURI"/Logout"
echo
