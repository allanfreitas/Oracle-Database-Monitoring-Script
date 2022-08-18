set lines 350
set feedback off
column MB format 99,999,999
column status format a65

select
   a.STATUS || ' ' || COMMAND_ID  || ' ' || a.INPUT_TYPE  as status,
   round(a.INPUT_BYTES/(1024*1024)) as INPUT_MB,
   a.SESSION_KEY,
   to_char(a.START_TIME,'mm/dd/yy hh24:mi') start_time,
   to_char(a.END_TIME,'mm/dd/yy hh24:mi') end_time,
   round(a.OUTPUT_BYTES/(1024*1024)) as OUTPUT_MB,
   round(a.elapsed_seconds/3600,2)  elapsed_hrs
from
   V\$RMAN_BACKUP_JOB_DETAILS a
where
   trunc(a.start_time) >= trunc(sysdate) - 2
order by
   session_key;
quit;