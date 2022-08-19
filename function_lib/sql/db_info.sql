
select '{ "Name": "'||d.name ||'",'||chr(10)||
  '"DB Unique Name": "'||d.db_unique_name ||'",'||chr(10)||
  '"Database Role": "'||d.database_role ||'",'||chr(10)||
  '"Created": "'||d.created ||'",'||chr(10)||
  '"Log Mode": "'||d.log_mode ||'",'||chr(10)||
  '"Flashback on": "'||d.flashback_on||'",'||chr(10)||
  '"Open Mode": "'||d.open_mode ||'",'||chr(10)||
  '"Data Guard Broker": "' ||d.dataguard_broker||'",'||chr(10)||
  '"Force Logging": "'||d.force_logging||'",'||chr(10)||
  '"Version": "' ||v.banner ||'",'||chr(10)||
  '"Is Container DB": "'||d.CDB||'",'||chr(10)||
  '"Hosts": "'||i.hosts||'",'||chr(10)||
  '"DB or PDBs": "'||ic.pdb_info||'",'||
  '}'
    from V$DATABASE d, V$VERSION v, 
    (select LISTAGG(host_name, ',')  within group (order by host_name) as hosts from gv$instance) i,
    (select  LISTAGG(pdb_info, '\n') within group (order by pdb_info) as pdb_info
from  (
select c.name ||
  ' ('||c.open_mode ||')'||
  ' v' || regexp_substr(v.banner,'\d+(\.\d)+') ||
  ' size: '|| trunc(c.TOTAL_SIZE/1024/1024/1024,2) ||' GB' as pdb_info
    from V$CONTAINERS c, V$VERSION v, V$DATABASE d
  where v.banner like '%Oracle Database%'
  order by c.CON_ID)) ic
  where v.banner like '%Oracle Database%'
/
select  LISTAGG(pdb_info||chr(13), ',') within group (order by pdb_info) as pdb_info
from  (
select c.name ||
  '('||c.open_mode ||'",'||
  '"Version": "' || regexp_substr(v.banner,'\d+(\.\d)+')||'"}' as pdb_info
    from V$CONTAINERS c, V$VERSION v, V$DATABASE d
  where v.banner like '%Oracle Database%'
  order by c.CON_ID);


select  LISTAGG(pdb_info, '\n') within group (order by pdb_info) as pdb_info
from  (
select c.name ||
  '('||c.open_mode ||')'||
  '-' || regexp_substr(v.banner,'\d+(\.\d)+') ||
  ' size: '|| trunc(c.TOTAL_SIZE/1024/1024/1024,2) ||' GB' as pdb_info
    from V$CONTAINERS c, V$VERSION v, V$DATABASE d
  where v.banner like '%Oracle Database%'
  order by c.CON_ID)


--- need to work on getting size properly
select  LISTAGG(pdb_info, '\n') within group (order by pdb_info) as pdb_info
from  (
select c.name ||
  '('||c.open_mode ||')'||
  '-' || regexp_substr(v.banner,'\d+(\.\d)+') ||
  ' size: '||sum(cdf.bytes)/1024/1024/1024 as pdb_info
    from V$CONTAINERS c, V$VERSION v, V$DATABASE d, cdb_data_files cdf
  where v.banner like '%Oracle Database%'
  group by cdf.CON_ID, c.CON_ID, d.CON_ID
  order by c.CON_ID)


select  LISTAGG(pdb_info, ',') within group (order by pdb_info) as pdb_info
from  (select '{ "Name": "'||c.name ||'",'||
  '"Open Mode": "'||c.open_mode ||'",'||
  '"Version": "' || regexp_substr(v.banner,'\d+(\.\d)+')||'"}' as pdb_info
    from V$CONTAINERS c, V$VERSION v, V$DATABASE d
  where v.banner like '%Oracle Database%'
  order by c.CON_ID)


select 'Name: '||d.name ||chr(10)||
       'DB Unique Name: '||d.db_unique_name ||chr(10)||
       'Database Role: '||d.database_role ||chr(10)||
       'Created: '||d.created ||chr(10)||
       'Log Mode: '||d.log_mode ||chr(10)||
       'Flashback on: '||d.flashback_on||chr(10)||
       'Open Mode: '||d.open_mode ||chr(10)||
       'Data Guard Broker:' ||d.dataguard_broker||chr(10)||
       'Force Logging: '||d.force_logging||chr(10)||
       'Version: ' ||v.banner||chr(30)
  from V$CONTAINERS c, V$DATABASE d, V$VERSION v
  where v.banner like '%Oracle Database%'
  order by c.CON_ID
/

select JSON_OBJECT(*) from v$database;
select JSON_OBJECT(KEY 'Name' is name,
       KEY 'DB Unique Name' is db_unique_name
)
from v$database;

select JSON_OBJECT('Name' is d.name,
       'DB Unique Name' is d.db_unique_name,
       'Database Role' is d.database_role,
       'Created' is d.created,
       'Log Mode' is d.log_mode,
       'Flashback on' is d.flashback_on,
       'Open Mode' is d.open_mode,
       'Data Guard Broker' is d.dataguard_broker,
       'Force Logging' is d.force_logging,
       'Version' is v.banner
       )
  from V$CONTAINERS c, V$DATABASE d, V$VERSION v
  where v.banner like '%Oracle Database%'
  order by c.CON_ID
/


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