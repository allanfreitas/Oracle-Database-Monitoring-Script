running_jobs()
{

result=`${1}/bin/sqlplus -silent / as sysdba << EOF
set pagesize 0 feedback off verify off heading off echo off;
SELECT distinct '{' || chr(10) || '"Job Name" : "' ||  r.JOB_NAME || '",' || chr(10) || '"Owner" : "' ||r.owner ||'",'|| chr(10) || '"Start Time" : "' || TO_CHAR(s.sql_exec_start,'DD-Mon-YYYY | HH12:MI:SSPM') ||'",'|| chr(10) || '"Elapsed Time" : "' || (sysdate-s.sql_exec_start)*24*60*60 ||' Sec",'|| chr(10) || '"CPU Used" : "' || r.cpu_used ||'",'|| chr(10) || '"Session Id" : "' || r.session_id ||'",'|| chr(10) || '"Run Count" : "' ||j.run_count || '",' || chr(10) || '},' FROM CDB_SCHEDULER_RUNNING_JOBS r LEFT JOIN CDB_SCHEDULER_JOB_RUN_DETAILS d ON d.SLAVE_PID = r.SLAVE_PROCESS_ID join cdb_scheduler_jobs j on j.job_name=r.job_name join gv\\$session s on r.session_id=s.sid and r.running_instance=s.inst_id;
exit;
EOF`
if [ "$result" == "" ];then
        echo -e "\n\"Running Jobs\" : \"None\",";
else
        echo -e "\n\"Running Jobs\": \n["
        #echo -e "\n\"Job_Name,Owner,Actual_Start_Date,Elapsed_Time,CPU_Used,Session_ID,Run_Count"

SaveIFS="$IFS";
IFS=$'\n';
for i in ${result[@]}; do echo -e  "$i"; done
echo -e '],'
fi
}
