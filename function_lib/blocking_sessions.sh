blocking_sessions()
{


result=`${1}/bin/sqlplus -silent / as sysdba << EOF
set pagesize 0 feedback off verify off heading off echo off;
SELECT distinct '{'|| chr(10)|| '"Blocking Session" : "' ||s.blocking_session ||'",'|| chr(10) || '"Blocked Session" : "' || s.sid ||'",'|| chr(10) || '"Blocked Serial#" : "' || s.serial# ||'",'|| chr(10) || '"Instance Name" : "' ||i.instance_name ||'",'|| chr(10) || '"Blocked Session Sql ID" : "' || l.sql_id ||'",'|| chr(10) || '"Wait Class" : "' || s.wait_class ||'",'|| chr(10) || '"Event" : "' || s.event || '",'|| chr(10) || '"Waiting Since" : "' || round(s.seconds_in_wait/60,2) ||' Sec",'|| chr(10)|| '"Container(ID)" : "' || c.name || '(' || s.con_id || ')",' || chr(10) || '},' FROM gv\\$session s, gv\\$sql l, gv\\$instance i, gv\\$containers c WHERE s.blocking_session is not NULL and s.sql_id=l.sql_id and s.inst_id=i.inst_id and s.con_id=c.con_id;
exit;
EOF`
        if [ "$result" == "" ];then
                echo -e "\n\"Blocking Sessions\": \"None\","
        else
                echo -e "\n\"Blocking Sessions\": \n["
                #echo -e "\n\"BLOCKING_SESSION, BLOCKED_SESSION, BLOCKED_SERIAL#, INSTANCE_NAME, BLOCKED_SESSION_SQL_ID, WAIT_CLASS, EVENT, WAIT_TIME(min),CON_NAME"

SaveIFS="$IFS";
IFS=$'\n';
for i in ${result[@]}; do echo -e  "$i"; done
echo -e '],'
fi
}