set pages 0 head off lines 200 feedback off
set serveroutput on size 1000000
select '# ---------------------------------------------------------'||chr(10)||
       '# -- Below OBJECTS are analyzed recently (within 10days) --'||chr(10)||
       '# ---------------------------------------------------------'||chr(10)
from dual;
set pages 0 lines 500
col OWNERS format a80
select Last_Analyzed, rtrim (xmlagg (xmlelement ("o",OWNER||':'||NO_OF_OBJECTS|| ' ,')).extract ('//text()'),',') OWNERS
from
 (select owner, to_char(trunc(last_analyzed),'mm-dd-yy') Last_Analyzed, 
count(*) NO_OF_OBJECTS from dba_tables where last_analyzed > SYSDATE -100 and 
OWNER not in ('SYS','SYSMAN','SYSTEM','SCOTT','MGMT_VIEW','ODM','ODM_MTR','OE','OLAPSYS','DBSNMP','PERFSTAT','XDB')
 group by owner,trunc(last_analyzed))
 group by Last_Analyzed order by 1 asc;
select '# ------------------------------------------------------------------'||chr(10)||
       '# --  Below OBJECTS are not analyzed recently (older than 10days) --'||chr(10)||
       '# ------------------------------------------------------------------'||chr(10)
from dual;
col OWNERS format a100
select rtrim (xmlagg (xmlelement ("o",OWNER||':'||count(*)|| ' ,')).extract ('//text()'),',') OWNERS
from
 dba_tables where last_analyzed < SYSDATE -10 and 
OWNER not in ('SYS','SYSMAN','SYSTEM','SCOTT','MGMT_VIEW','ODM','ODM_MTR','OE','OLAPSYS','DBSNMP','PERFSTAT','XDB') 
group by owner
order by 1 asc;
quit