#!/bin/sh

export CLIENTNAME="ESDC10WIN004POC"
export CLIENTIP="10.60.19.104"
export STORAGEPOLICY="storp01"
export SCHEPNAME="schep01"
export CLIENTGROUPNAME="clientgroup01"
export CLIENTHOSTNAME=$CLIENTNAME.esdc10.local

## APPNAME can be "Windows File System", "SQL Server", "Linux File System", "MySQL" or "Virtual Server" ##
export APPNAME="Windows File System"

## Set DATABASES for databases if necessary. e.g. "mysql db01". ##
# export DATABASES="testdb db01"

## Set VM as Virtual Machine name if necessary. Only single item is allowed. ##
# export VM="ESDC10WIN002POC"
