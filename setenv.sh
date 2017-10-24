#!/bin/sh

export BASEURI="http://10.60.19.17:81/SearchSvc/CVWebService.svc"
export HEADER1="Accept:application/xml"
export HEADER2="Content-Type:application/xml"
export HEADER3="Host:esdc10hdp002poc"
USERNAME="admin"
B64PW="UGh5cyEwMTBneQ=="

export TOKEN=$(curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -d '<DM2ContentIndexing_CheckCredentialReq mode="Webconsole" username="'$USERNAME'" password="'$B64PW'" />' -L $BASEURI"/Login" | xmlstarlet sel -t -v DM2ContentIndexing_CheckCredentialResp/@token)

export CURLCMD="curl -s -H $HEADER1 -H $HEADER2 -H $HEADER3 -H \"Authtoken:$TOKEN\""

disp()
{
        echo
        echo "==============================="
        echo "$@"
        echo "==============================="
}

source $(dirname ${BASH_SOURCE[0]})/testcase.sh

