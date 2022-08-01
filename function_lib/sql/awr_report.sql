spool ${awr_report}/awr_rpt.sql
set pagesize 0 linesize 200 heading off feedback off
select 'define dbid='||DBID from v\$database;
select 'define instt_num='||INSTANCE_NUMBER from v\$instance;
select 'define instt_name='||INSTANCE_NAME from v\$instance;
select 'define dbb_name='||NAME from v\$database;
select 'define host='||HOST_NAME from v\$instance;
select 'define end_snap='||max(snap_id) from dba_hist_snapshot;
select 'define begin_snap='||snap_id from (select SNAP_ID from dba_hist_snapshot 
where begin_interval_TIME > SYSDATE - 1.08 order by 1 asc) where rownum = 1;
select 'define report_type=text' from dual;
select 'define report_name=awr_report_$dbname.txt' from dual;
select 'define num_days=2' from dual;
select '@?/rdbms/admin/awrrpt.sql' from dual;
spool off
@${awr_report}/awr_rpt.sql
quit;