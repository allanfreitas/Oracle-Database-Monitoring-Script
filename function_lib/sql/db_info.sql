set pages 0 lines 300 trims on head off feed off ver off
select '# ---------------------------'||chr(10)||
       '# --  Instance Information --'||chr(10)||
       '# ---------------------------'||chr(10)
from dual;
select 'Host Name: '||host_name||chr(10)||
       'Instance ID: '||inst_id||chr(10)||
       'Instance Name: '||instance_name||chr(10)||
       'Version: '||version||chr(10)||
       'Startup Time: '||to_char(startup_time, 'DD-MON-RR HH24:MI:SS')||chr(10)||
       'Instance Role: '||instance_role||chr(10)||
       'Blocked:' ||blocked
from gv\$instance order by inst_id asc
/
select '# ---------------------------'||chr(10)||
       '# --  Database Information --'||chr(10)||
       '# ---------------------------'||chr(10)||
       'Name: '||name ||chr(10)||
       'Database Role: '||database_role ||chr(10)||
       'Created: '||created ||chr(10)||
       'Log Mode: '||log_mode ||chr(10)||
       'Open Mode: '||open_mode ||chr(10)||
       'Protection Mode: '||protection_mode ||chr(10)||
       'Protection Level: '||protection_level ||chr(10)||
       'Current SCN: '||current_scn ||chr(10)||
       'Flashback on: '||flashback_on||chr(10)||
       'Open Mode: '||open_mode ||chr(10)||
--       'Primary DB Unique Name: '||primary_db_unique_name ||chr(10)||
       'DB Unique Name: '||db_unique_name ||chr(10)||
       'Archivelog Change#: '||archivelog_change# ||chr(10)||
--       'Archivelog Compression: '||archivelog_compression ||chr(10)||
       'Switchover Status: '||switchover_status ||chr(10)||
       'Remote Arachive: '||remote_archive||chr(10)||
       'Supplemental Log PK: '||supplemental_log_data_pk||' - '||
         'Supplemental Log UI: '||supplemental_log_data_ui||chr(10)||
       'Data Guard Broker:' ||dataguard_broker||chr(10)||
       'Force Logging: '||force_logging 
  from v\$database
/
select 'Database Size: '||trunc(sum(used.bytes) / 1024 / 1024 / 1024, 2)  || ' GB' ||chr(10)||
'Logfile Size: '||trunc(log.l / 1024 / 1024 , 2)  || ' MB' ||chr(10)||
    'Free Space: '||trunc(free.p / 1024 / 1024 / 1024, 2) || ' GB'
from (select bytes from v\$datafile 
      union all 
      select bytes from v\$tempfile) used 
,     (select sum(bytes) as l from v\$log) log 
,    (select sum(bytes) as p from dba_free_space) free 
group by free.p, log.l
/
set numwidth 5 
column name format a30 tru 
column value format a48 wra 
select '# ------------------------------------'||chr(10)||
       '# --    NoN Default Parameters      --'||chr(10)||
       '# ------------------------------------'||chr(10)
from dual;
select inst_id, name, value 
from gv\$parameter 
where isdefault = 'FALSE' or name = 'spfile'
order by name, inst_id asc;
quit;