#!/bin/sh

#  check_dg_gap.sh
#Created:2016-12-19
#Updated:2016-12-19
#Author: skyecool
#Description:Check the DG gap fail,and register automic

#set Oracle environment for Sql*Plus
export ORACLE_BASE=$ORACLE_BASE
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/db_1
export ORACLE_SID=dbsid
export NLS_LANG=AMERICAN_AMERICA.ZHS16GBK
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/oracm/lib:/lib:/usr/lib:/usr/local/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export TMP=/tmp
export TMPDIR=/tmp
export PATH=$ORACLE_HOME/bin:$GRID_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME/rdbms/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/JRE:$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib:$ORACLE_HOME/network/jlib

#Get the gap sequence# by quering v$archive_gap
GAP_SEQ=`
sqlplus -s / as sysdba <<EOF
set echo off feedback off heading off underline off;
select THREAD#,LOW_SEQUENCE# from v\\$archive_gap;
exit;
EOF`


echo "gap sequence# is: $GAP_SEQ"

THREADID=`echo $GAP_SEQ |awk '{print $1}'`
SEQID=`echo $GAP_SEQ |awk '{print $2}'`

if [ -n "$SEQID" ]; then
GAP_LOG_FILE=$THREADID"_"$SEQID"_xxxxdbid.dbf"
echo "logfile is $GAP_LOG_FILE"

REG_LOG_COM(){
sqlplus -s / as sysdba <<EOF
alter database register logfile '/arch/$GAP_LOG_FILE';
exit;
EOF
}

if [ ! -f "/arch/$GAP_LOG_FILE" ]; then
if [ $THREADID -eq 1 ]; then
expect -c  "spawn scp -r oracle@ip:/arch/$GAP_LOG_FILE /arch/
expect {
\"*assword\" {set timeout 300; send \"password\r\"; set timeout -1;}
\"yes/no\" {send \"yes\r\"; exp_continue;}
}
expect eof"
REG_LOG_COM
elif [ $THREADID -eq 2 ]; then
expect -c  "spawn scp oracle@ip:/arch/$GAP_LOG_FILE /arch/
expect {
\"*assword\" {set timeout 300; send \"password\r\"; set timeout -1;}
\"yes/no\" {send \"yes\r\"; exp_continue;}
}
expect eof"
REG_LOG_COM
else
echo "thread dose not exists!"
fi
else
REG_LOG_COM
fi

else
echo "NO GAP!"
fi
