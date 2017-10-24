#!/bin/sh

export CLIENTNAME="esdc10rhl005poc"
export CLIENTIP="10.60.19.108"
export STORAGEPOLICY="storp01"
export SCHEPNAME="schep01"
export CLIENTGROUPNAME="clientgroup01"
export CLIENTHOSTNAME=$CLIENTNAME.esdc10.local
export MACLIENTID1="2"
export MAIP1="10.60.19.17"
export MACLIENTID2="14"
export MAIP2="10.60.19.16"
export OLDSTORAGEPOLICY="storp00"

## APPNAME can be "Windows File System", "SQL Server", "Linux File System", "MySQL" or "Virtual Server" ##
export APPNAME="Linux File System"

## Set DATABASES for databases if necessary. e.g. "mysql db01". ##
# export DATABASES="testdb db01"

## Set VM as Virtual Machine name if necessary. Only single item is allowed. ##
# export VM="ESDC10WIN002POC"
