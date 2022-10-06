active_sessions()
{

result=`${1}/bin/sqlplus -silent / as sysdba << EOF
set pagesize 0 feedback off verify off heading off echo off;
select '{' || chr(10) || '"Container" : "' || s.con_id || '(' || c.name || ')",' || chr(10) || '"Active Sessions" : "' || count(s.sid) || '",' || chr(10) || '},' from gv\\$session s, gv\\$containers c where status='ACTIVE' and type<>'BACKGROUND' and s.con_id=c.con_id group by s.con_id,c.name;
exit;
EOF`
if [ "$result" == "" ];then
        echo -e "\n\"Active Sessions\": \"None\","
else
        echo -e "\n\"Active Sessions\": \n["
        # echo -e "\n\"CON_ID,ACTIVE_SESSIONS"

SaveIFS="$IFS";
IFS=$'\n';
for i in ${result[@]}; do echo -e  "$i"; done
echo -e '],'
fi
}