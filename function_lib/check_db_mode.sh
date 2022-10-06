check_db_mode()
{
#echo "OHOME=$1"
#echo "DB=$2"
result=`${1}/bin/sqlplus -silent / as sysdba << EOF
set pagesize 0 feedback off verify off heading off echo off;
select open_mode from v\\$database;
exit;
EOF`

#if [ "$result" == "" ];then
#        echo -e "$result"
#else
#        #echo -e "N"

SaveIFS="$IFS";
IFS=$'\n';
for i in ${result[@]}; do echo -e  "$i"; done
#echo -e '",'
#fi
}
