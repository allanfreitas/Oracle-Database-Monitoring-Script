rman_backup_status()
{

#THRESHOLD Value is for getting backup information for last n days
THRESHOLD=1;

result=`${1}/bin/sqlplus -silent / as sysdba << EOF
set pagesize 0 feedback off verify off heading off echo off;
select '{' || chr(10) || '"' || input_type || ' Backups" : "' || status || '(' || count(input_type) || ')",' || chr(10) || '"Input Bytes" : "' || round(sum(input_bytes/1024/1024/1024), 2) || ' GB",' ||chr(10)|| '"Output Bytes" : "' ||round(sum(output_bytes/1024/1024/1024),2) || ' GB",' ||chr(10) || '"Time Taken" : "' || round(sum(elapsed_seconds/3600),2) || ' Hrs"'|| chr(10)|| '},' as "RMAN Backup Status" from v\\$RMAN_BACKUP_JOB_DETAILS where trunc(start_time) >= trunc(sysdate-${THRESHOLD}) group by input_type,status;
exit;
EOF`

if [ "$result" == "" ];then
         echo -e "\n\"RMAN Backup Information For Last ${THRESHOLD} Days\": \"None\","
        #echo -e "\nAll Tablespaces Are Under Threshold(${THRESHOLD}%) Limit\n"
else
         echo -e "\n\"RMAN Backups In Last ${THRESHOLD} Days\": \n["


SaveIFS="$IFS";
IFS=$'\n';
for i in ${result[@]}; do echo -e  "$i"; done
echo -e '],'
fi
}
