tablespace_alert()
{

#Set THRESHOLD value to check tablespace filled above n %
THRESHOLD=85;

result=`${1}/bin/sqlplus -silent / as sysdba << EOF
set pagesize 0 feedback off verify off heading off echo off;
select '{' || chr(10) || '"Tablespace Name" : "' || t.tablespace_name || '",' || chr(10) || '"Percentage Used" : "' || round(t.used_percent,2) || '%",' || chr(10) || '"Container" : "' || c.con_id || '(' || c.name || ')",' || chr(10) || '},'  from  cdb_tablespace_usage_metrics t , gv\\$containers c where t.used_percent>=${THRESHOLD} and t.con_id=c.con_id;
exit;
EOF`

if [ "$result" == "" ];then
         echo -e "\n\"Tablespaces Usage Above ${THRESHOLD}%\": \"None\","
        #echo -e "\nAll Tablespaces Are Under Threshold(${THRESHOLD}%) Limit\n"
else
         echo -e "\n\"Tablespace Above ${THRESHOLD}%\": \n["


SaveIFS="$IFS";
IFS=$'\n';
for i in ${result[@]}; do echo -e  "$i"; done
echo -e '],'
fi
}