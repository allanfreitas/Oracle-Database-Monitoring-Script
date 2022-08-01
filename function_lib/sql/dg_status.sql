set pages 0
set lines 350 feedback off
set serveroutput on size 1000000
set lines 132
col error format a32
col destination format a35
set ver off head off feed off pages 0
set serveroutput on size 1000000
set lines 132
set pagesize 9999 feed off ver off trims on
DECLARE
pad10 CHAR(10) := ' ';
cursor c2 is
select PID,process,status,SEQUENCE# , THREAD# from v\$managed_standby;
cursor c3 is
SELECT NAME,UNIT FROM V\$DATAGUARD_STATS WHERE NAME='apply lag';

cursor c4 is
select count(*) ANA from gv\$archived_log where applied='NO' and registrar='RFS' and creator='ARCH' order by sequence#;

BEGIN
dbms_output.put_line('# ---------------------------------------------------- #');
for r3 in c3 loop
  dbms_output.put_line('Apply Lag in Time: '||r3.UNIT);
end loop;
dbms_output.put_line('# ---------------------------------------------------- #');
for r4 in c4 loop
  dbms_output.put_line('Archive Logs not Applied: '||r4.ANA);
end loop;
dbms_output.put_line('# ---------------------------------------------------- #');
for r2 in c2 loop
  dbms_output.put_line('Process:	'||r2.PID ||'	Processor Name:	'||r2.process||'	Status: '||
r2.STATUS||'	Sequence#:	'||r2.SEQUENCE#||'	THREAD#:	'||r2.THREAD#);
end loop;
dbms_output.put_line('# ---------------------------------------------------- #');
END;
/
quit;