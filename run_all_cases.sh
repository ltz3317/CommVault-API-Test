#!/bin/sh

DIR=$(dirname $0)
for FILE in `ls $DIR/testcase-*.sh`
do
	cp -p $FILE $DIR/testcase.sh
	echo "************************"
	echo "RUNNING $FILE."
	echo "************************"
	# $DIR/updateall.sh
	$DIR/fallback.sh
done

