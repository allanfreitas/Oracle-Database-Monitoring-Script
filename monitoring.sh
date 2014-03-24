#------------------------------------------------------------------------------------------------
# README ME
#------------------------------------------------------------------------------------------------
# PURPOSE	:Checks Filessytem space,ASM space, Listener,Tablespace,CRS_STAT, RMAN Backups, Index Fragmentation, Gather Stats, Alert Log, 
#         	pulls AWR Report(last 24hours),(MRP,Archive gap,Archive apply lag)Standby etc
# 
# PLATFORM	:SunOS,HP-UX,AIX and Linux 
#
# ORACLE DB Version	: Works fine with all versions >10.1. Certain functionality will dont work in 9i. Not compatible with any version < 9i
# 
# 
# How to Run?	:1. Run the script with full path from any location (for example "/home/oracle/daily_monitoring.sh" and enter)
#		 2. You can edit the threshold values/email recipient address as mention in below Sub-heading.
#		 3. The exact entries of INSTANCE NAME should be presend in default "oratab" or you can create /tmp/c_oratab and add the instance name
#		    and oracle home in the formate of "<INSTANCE_NAME>:<INSTANCE_HOME>:[Y|N]". The script will first look for /tmp/c_oratab if it is  
#		    not present it will consider default ORATAB.
#
# If crs is present?	: Run this script from any one node, it will capture all the Database Instances information from that node and 
#			it will automatically spawn in other nodes to gather the alert information and space information.
#			
# 
#
# NOTE		:Make sure to open this file in notepad with max size while copying it to the VI Editor. Sometimes when copying from notepad to vi editor 
#               few long lines in the script may breaks and throws error when running. Figure out the broken lines and modify as needed.
#		It works well if you copy it from any  widescreen laptop/monitor.
#		
#       
#
#
# AUTHOR	:Srikanth Marni
# REV DATE	:06/02/2011
# REV		:1.1.1
#  @copyright   (c) 2013 - 2014 Veera Srikanth Marni
#  @license     MIT
#
#set -x 
########################################
# Modification: 07/13/2012: Modified case $(uname) to case ${uname} and added uname=`uname`
#
#
############################################################################################################
#
#   Modify the below threshold values
#
########################################################
FILESYSTEM_SpaceThreshold=60		### Edit the threshold value for Filesystem used percent
ASM_SpaceThreshold=10			### Edit the threshold value for ASM Filesystem used percent
alert_pointer=1000			### Edit the tail value for checking the alert log
TB_CRITICAL_Threshold=80		### Edit the Tablespace Critical warning Threshold
TB_WARN_Threshold=70			### Edit the Tablespace Warning Threshold
recipient=srikanth.marni@biascorp.com	### Edit the recipient address for sending email. If there are more recipient then add them with comma(',') as sperator
					### example: recipient=user1@domain.com,user2@domain.com
sender=monitoring@servername.com
######################################################
#  Below is for seperation and sending alerts to mail 
######################################################
seperate()
{
${ECHO} "\n==========================================================================================" >> ${logs}/Alert.log
}
divide()
{
echo "------------------" >> ${logs}/Alert.log
}
fdivide()
{
${ECHO} "\n\n------------------" >> ${logs}/Alert.log
}
notify()
{
case ${uname} in
Linux)
mailx -s "${prepend_sub}" ${recipient} -- -f ${sender} < ${output_file}
;;
*) 
mailx -s "${prepend_sub}" ${recipient} `hostname`@monitoring.com -f ${sender} < ${output_file}
;;
esac
}
#####################################################
#####################################################
# Filesystem Space Check Method
#####################################################
CheckSpace ()
{
> ${fs_monitor}/fsspace_Check.log
case ${uname} in
Linux)
df -k | tail -n+2 |grep % | egrep -v '/mnt/cdrom|/dev/fd|/etc/mnttab|/proc|/dev/cd[0-9]' > ${fs_monitor}/fsmonitor.log
;;
*)
df -k | tail +2 |grep % | egrep -v '/mnt/cdrom|/dev/fd|/etc/mnttab|/proc|/dev/cd[0-9]'> ${fs_monitor}/fsmonitor.log
;;
esac	
if [ ! -s ${fs_monitor}/fsmonitor.log ]
then
echo "ERROR: Filesystem cannot be monitor, please monitor it manually" >> ${fs_monitor}/fsspace_Check.log 
fi
cat ${fs_monitor}/fsmonitor.log | while read fsdisk 
do
echo "fsdisk = $fsdisk"
Arg2=$(echo $fsdisk | ${AWK} -F '%' '{print $1}')
Partition2=$(echo $fsdisk | ${AWK} -F '%' '{print $2}')
kount=`echo $Arg2 |wc -c`
Percnt2=`echo $Arg2 | cut -c$((${kount}-2))-$((${kount}-1)) | ${AWK} '{print $1}'`
if [ ${Percnt2:-0} -gt ${FILESYSTEM_SpaceThreshold} ]
then
${ECHO} "\n The filesystem $Partition2 is ($Percnt2%) used on Server `hostname` as of `date`\n" >> ${fs_monitor}/fsspace_Check.log
fi
done
ALRTCNT3=`cat ${fs_monitor}/fsspace_Check.log | wc -l`
ALRTSTA3=0
if [ ${ALRTCNT3} -gt ${ALRTSTA3} ]; then
echo "Filesystem Space alert on server `hostname` and date `date`" >> ${logs}/Alert.log
cat ${fs_monitor}/fsspace_Check.log >> ${logs}/Alert.log
else
echo "No filesystem space issue as of `date`" >> ${logs}/Alert.log
fi
}
#####################################################
#####################################################
# Network Errors and Packet drops
#####################################################
netstat_check()
{
netstat -s | awk 'NF==1 {
 protocol=$0
 next}
  {match($0,"fragments dropped") || match($0,"packet receive errors") || match($0,"udpInOverflows")
if (RSTART>0) {
 printf("%s %s\n",protocol, $0)
RSTART=0
}
}
' >> ${logs}/Alert.log
}
#####################################################
# Monitor Index Fragmentation
#####################################################
index_rebuild()
{
echo CHECKING Index Fragmentation of ${ORACLE_SID} at `date`
sqlplus -s "/as sysdba" >${index_info}/index_frag_$dbname <<EOF12
set lines 500
col NEW_IDX_percentage format 999.99999
col idxname     format a38      head "Owner.Index"
col uniq        format a01      head "U"
col tsname      format a28      head "Tablespace"
col xtrblk      format 999999   head "Extra|Blocks"
col lfcnt       format 9999999  head "Leaf|Blocks"
col blk         format 9999999  head "Curr|Blocks"
col currmb      format 99999    head "Curr|MB"
col newmb       format 99999    head "New|MB"
select
  u.name ||'.'|| o.name  idxname,
  decode(bitand(i.property, 1), 0,' ', 1, 'x','?') uniq,
  ts.name tsname,
  seg.blocks blk,
  i.leafcnt lfcnt,
  floor((1 - i.pctfree$/100) * i.leafcnt - i.rowcnt * (sum(h.avgcln) + 11) / (8192 - 66 - i.initrans * 24)  ) xtrblk,
    round(seg.bytes/(1024*1024)) currmb,
  (1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24)) 
* seg.bytes/(1024*1024)) newmb,
  ((1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24)) 
* seg.bytes/(1024*1024)))*100/(seg.bytes/(1024*1024)) NEW_IDX_percentage,
  (100-((1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24)) 
* seg.bytes/(1024*1024)))*100/(seg.bytes/(1024*1024))) Benifit_percent
from
  sys.ind$  i,
  sys.icol$  ic,
  sys.hist_head$  h,
  sys.obj$  o,
  sys.user$  u,
  sys.ts$ ts,
  dba_segments seg
where
  i.leafcnt > 1 and
  i.type# in (1,4,6) and                -- exclude special types
  ic.obj# = i.obj# and
  h.obj# = i.bo# and
  h.intcol# = ic.intcol# and
  o.obj# = i.obj# and
  o.owner# != 0 and
  u.user# = o.owner# and
  i.ts# = ts.ts# and
  u.name = seg.owner and
  o.name = seg.segment_name and
  seg.blocks > i.leafcnt                -- if i.leafcnt > seg.blocks then statistics are not up-to-date
group by
   u.name,
  decode(bitand(i.property, 1), 0,' ', 1, 'x','?'),
  ts.name,
  o.name,
  i.rowcnt,
  i.leafcnt,
  i.initrans,
  i.pctfree$,
--p.value,
  i.blevel,
  i.leafcnt,
  seg.bytes,
  i.pctfree$,
  i.initrans,
  seg.blocks
 having
  50 * i.rowcnt * (sum(h.avgcln) + 11)
  < (i.leafcnt * (8192 - 66 - i.initrans * 24)) * (50 - i.pctfree$) and
  floor((1 - i.pctfree$/100) * i.leafcnt -
    i.rowcnt * (sum(h.avgcln) + 11) / (8192 - 66 - i.initrans * 24)  ) > 0 and
((1 + i.pctfree$/100) * (i.rowcnt * (sum(h.avgcln) + 11) / (i.leafcnt * (8192 - 66 - i.initrans * 24))
 * seg.bytes/(1024*1024)))*100/(seg.bytes/(1024*1024)) <80
and round(seg.bytes/(1024*1024)) > 50
order by 10,9, 2;
quit;
EOF12
ALRTCNT=`cat ${index_info}/index_frag_$dbname | wc -l`
ALRTSTA=0
if [ ${ALRTCNT} -gt ${ALRTSTA} ]; then
echo "Index Fragmented on $dbname" >> ${logs}/Alert.log
cat ${index_info}/index_frag_$dbname >> ${logs}/Alert.log
else
echo "No Index Fragementation Issue on $dbname" >> ${logs}/Alert.log
fi
}
#####################################################
#####################################################
# AWR REPORT Method 
#####################################################
awr_report()
{
echo CHECKING AWR report of ${ORACLE_SID} at `date`
cd ${awr_report}
sqlplus -s "/as sysdba" >${awr_report}/awr_report.log <<ART
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
ART
prepend_sub="AWR report of $dbname for last 24 hours, `hostname` ,`date`"
output_file=${awr_report}/awr_report_$dbname.txt
notify
}
#####################################################
#####################################################
# DATABASE ALERT METHOD
#####################################################
db_alert()
{
echo CHECKING DB Alert of ${ORACLE_SID} at `date`
export alrt_loc=`cat ${bdump_alerts}/bdump.$dbname |grep bdump |${AWK} '{print $1}'`
if [ -z "$alrt_loc" ]
then
export alrt_loc=`cat ${bdump_alerts}/bdump.$dbname |grep trace |${AWK} '{print $1}'`
echo "New Alert Location" 
fi
${ECHO} "~~~~~~~~~~~ALERT LOCATION : $alrt_loc ~~~~~~~~~~~~\n" >> ${logs}/Alert.log
#DATE="`date +%y/%m/%d`"
#YEAR="`date +%y -d last-week`"
#MONTH="`date +%h -d last-week`"
#DAY="`date +%d -d last-week`"
#WEEK="`date +%a -d last-week`"
#cat -n ${alrt_loc}/alert_$dbname.log |grep "$YEAR" |grep "$MONTH " |grep " $DAY " |grep $WEEK > ${bdump_alerts}/alrt_st_$dbname.log
#export ST=`head -1 ${bdump_alerts}/alrt_st_$dbname.log |cut -f1`
#if [ -z "$ST" ]
#then
tail -${alert_pointer} ${alrt_loc}/alert_${dbname}.log >> ${bdump_alerts}/TruncAlert7_$dbname.log
#else
#tail -n +$ST ${alrt_loc}/alert_${dbname}.log >> ${bdump_alerts}/TruncAlert7_$dbname.log
#fi
${AWK} 'NF==5 && ($1=="Mon" || $1=="Tue" || $1=="Wed" || $1=="Thu" || \
                $1=="Fri" || $1=="Sat" || $1=="Sun"){
        Date=$0
        ErrCnt=0
        next}
        {match($0,"ORA-")
                if (RSTART>0) {
                        ErrCnt++
                        printf("%d:%s: %s\n", ErrCnt,Date,$0)
                        RSTART=0
                }
        }
        ' ${bdump_alerts}/TruncAlert7_$dbname.log > ${bdump_alerts}/Ora_alert_${dbname}.log
ALRTCNT=`cat ${bdump_alerts}/Ora_alert_${dbname}.log | wc -l`
ALRTSTA=0
if [ ${ALRTCNT} -gt ${ALRTSTA} ]; then
${ECHO} "\nTotal ORA Alerts count ${ALRTCNT}\n" >> ${logs}/Alert.log
cat ${bdump_alerts}/Ora_alert_${dbname}.log >> ${logs}/Alert.log
else
${ECHO} "No DB ALERTS\n" >> ${logs}/Alert.log
fi
}
########################################################
########################################################
# Get Max function for finding CRS HOME
########################################################
function get_max
{
(($# == 0)) && return -1
echo $#
}
########################################################
########################################################
# CRS STATISTIC METHOD
########################################################
crs_stat2 ()
{
$1/crs_stat | ${AWK} -F= '
BEGIN { A="" ; B="" ; C="" ; D="" }
/^NAME/ { A=$2 }
/^TYPE/ { B=$2 }
/^TARGET/ { C=$2 ; if (C == "ONLINE") C=" ONLINE" }
/^STATE/ { D=$2 ; S="" ; if (D != "OFFLINE") S=" "
           printf "%-48s\t%s\t%s%s\n", A, C, S ,D }
' | sort 
}
########################################################
########################################################
# ASM SPACE METHOD
########################################################
asmspace()
{
${ECHO} CHECKING ASM SPACE of ${ORACLE_SID} at `date`
##Space is queried in the below start script and sents output to ${asm_space}/asm_space.log
### to remove empty lines sed '/^$/d'  ###
cat ${asm_space}/asm_space.log | sed '/^$/d' | ${AWK} -F ' ' '{print $2, $3, $5, $6, $7}' \
 | while read DISK_NAME MOUNT_STATUS TOTALSPACE FREESPACE USEDPERCENT
do
FREESPACE_GB=$(bc <<L1 
scale=2
$FREESPACE/1024
L1)
TOTALSPACE_GB=$(bc <<L2 
scale=2; $TOTALSPACE/1024
L2)
 ${ECHO} "\n Partition :$DISK_NAME Total Space is: ${TOTALSPACE_GB} and Free Space is: ${FREESPACE_GB}" >> ${logs}/Alert.log
if [ $USEDPERCENT -gt $ASM_SpaceThreshold ]; then
    ${ECHO} "\n ATTENTION! The filesystem ${DISK_NAME} is ($USEDPERCENT)%used on 
Server `hostname` as of `date` with freespace= ${FREESPACE_GB} GB 
and total space= ${TOTALSPACE_GB} GB \n" >> ${asm_space}/asm_space_alert.log
fi
done
ALRTCNT=`cat ${asm_space}/asm_space_alert.log | wc -l`
ALRTSTA=0
if [ ${ALRTCNT} -gt ${ALRTSTA} ]; then
${ECHO} "\n ******ASM SPACE issue on `date`. Please check below for more info ******" >> ${logs}/Alert.log
cat ${asm_space}/asm_space_alert.log >> ${logs}/Alert.log
else
${ECHO} "\n =======No ASM Space issue as of `date`========" >> ${logs}/Alert.log
fi
}
###########################################################
###########################################################
# Gather Statistic info method
###########################################################
gather_stats_rpt()
{
${ECHO} CHECKING Gather Statistics of ${ORACLE_SID} at `date`
sqlplus -s "/as sysdba" >${db_info}/statistics_rpt_$dbname <<EOF11
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
EOF11
cat ${db_info}/statistics_rpt_$dbname >> ${logs}/Alert.log
}
############################################################
############################################################
# Tablespace check method
############################################################
Tablespace()
{
${ECHO} CHECKING Tablespace ${ORACLE_SID} at `date`
sqlplus -s "/as sysdba" >${ts_monitor}/ts_$dbname <<EOF
set pagesize 0 linesize 200 heading off feedback off
column total_bytes format 999999999999999
column free_gb format 999999999999999
column maxsize_gb format 999999999999999
select x.tablespace, x.free_gb,x.size_gb,x.maxsize_gb, trunc( (1- (x.free_gb/x.maxsize_gb))*100, 2) percent_used, 
round((1- (x.free_gb/x.maxsize_gb))*100,0) Percent from
(select 
  a.tablespace_name tablespace
 ,sum((a.maxsize-a.bytes+b.free)/1024/1024/1024) free_gb
 ,sum(a.bytes/1024/1024/1024) size_gb
 ,sum(a.maxsize/1024/1024/1024) maxsize_gb
 from
  (select 
         tablespace_name
        ,sum(bytes) bytes
        ,sum(decode(autoextensible,'YES',maxbytes,bytes)) maxsize
   from dba_data_files 
   group by tablespace_name) a,
  (select tablespace_name, sum(bytes) free
from dba_free_space
group by tablespace_name) b
where a.tablespace_name=b.tablespace_name(+)
group by a.tablespace_name) x
where trunc( (1- (x.free_gb/x.maxsize_gb))*100, 2) > 80 
order by trunc( (1- (x.free_gb/x.maxsize_gb))*100, 2);
quit;
EOF
> ${ts_monitor}/tb_$dbname.log
cat ${ts_monitor}/ts_$dbname |while read line1
do
#wt=70#ct=80
Tablespace=`${ECHO} $line1 | ${AWK} '{print $1}'`
freesize_GB=`${ECHO} $line1 | ${AWK} '{print $2}'`
Maxsize_GB=`${ECHO} $line1 | ${AWK} '{print $4}'`
Percent=`${ECHO} $line1 | ${AWK} '{print $6}'`
Percent_used=`${ECHO} $line1 | ${AWK} '{print $5}'`
if [ ${Percent} -gt ${TB_CRITICAL_Threshold} ] 
then
${ECHO} "\n CRITICAL WARNING! ${Tablespace} is ${Percent_used}%used. With Maximum Size 
(including all the auto extensible datafiles) of ${Maxsize_GB} GB and freespace of ${freesize_GB} GB \n" >> ${ts_monitor}/tb_$dbname.log
elif [ $Percent -gt ${TB_WARN_Threshold} ] 
then
${ECHO} "\n WARNING! ${Tablespace} is ${Percent_used}%used. With Maximum Size 
(including all the auto extensible datafiles) of ${Maxsize_GB} GB and 
freespace of ${freesize_GB} GB \n" >> ${ts_monitor}/tb_$dbname.log
fi
done
ALRTCNT=`cat ${ts_monitor}/tb_$dbname.log | wc -l`
ALRTSTA=0
if [ ${ALRTCNT} -gt ${ALRTSTA} ]; then
${ECHO} "Tablespace issue on $dbname" >> ${logs}/Alert.log
cat ${ts_monitor}/tb_$dbname.log >> ${logs}/Alert.log
else
${ECHO} "No Tablespace Issue on $dbname" >> ${logs}/Alert.log
fi
}
#########################################################
#########################################################
# Primary Database Information
#########################################################
prim_dr()
{
${ECHO} CHECKING Dataguard infromation of ${ORACLE_SID} at `date`
sqlplus -s "/as sysdba" >${dg_report}/dg_report_$dbname << CDG1
set pages 0
set lines 350 feedback off
set serveroutput on size 1000000
set lines 132
col error format a32
col destination format a35
set ver off head off feed off pages 0
DECLARE
pad10 CHAR(10) := ' ';
CURSOR c1 is
select s.inst_id,
       s.db_unique_name,
       s.database_mode,
       s.dest_id id, s.status stats, 
       s.recovery_mode,
       s.protection_mode, s.standby_logfile_count,
       s.standby_logfile_active,
       s.archived_thread#, s.archived_seq#, s.applied_thread#, s.applied_seq#,
       d.status, d.destination, d.archiver,
       d.transmit_mode, d.affirm, d.async_blocks,
       d.net_timeout, d.delay_mins, d.reopen_secs,
       d.register, d.binding, 
--d.compression, 
       d.error err
from gv\$archive_dest_status s, gv\$archive_dest d
where d.dest_id=s.dest_id
and d.inst_id=s.inst_id
and s.db_unique_name <> 'NONE'
and d.destination is not null
order by inst_id asc;

BEGIN
dbms_output.put_line('---------------------------------------------------------------------------------------');
FOR r1 IN c1 LOOP
  dbms_output.put_line('Dest ID: '||r1.id||pad10||'Status: '||r1.stats);
  dbms_output.put_line('DB Name: '||r1.db_unique_name||pad10||'DB Mode: '||r1.database_mode);
  dbms_output.put_line('Recovery Mode: '||r1.recovery_mode);
  dbms_output.put_line('Protection Mode: '||r1.protection_mode);
  dbms_output.put_line('SRL Count: '||r1.standby_logfile_count||pad10||'SRL Active: '||r1.standby_logfile_active);
  dbms_output.put_line('Archived Thread#: '||r1.archived_thread#||pad10||'Archived Seq#: '||r1.archived_seq#);
  dbms_output.put_line('Applied Thread#: '||r1.applied_thread#||pad10||'Applied Seq#: '||r1.applied_seq#);
  dbms_output.put_line('Destination: '||r1.destination);
  dbms_output.put_line('Archiver: '||r1.archiver);
  dbms_output.put_line('Transmit Mode: '||r1.transmit_mode);
  dbms_output.put_line('Affirm: '||r1.affirm);
  dbms_output.put_line('Asynchronous Blocks: '||r1.async_blocks);
  dbms_output.put_line('Net Timeout: '||r1.net_timeout);
  dbms_output.put_line('Delay (Mins): '||r1.delay_mins);
  dbms_output.put_line('Reopen (Secs): '||r1.reopen_secs);
  dbms_output.put_line('Register: '||r1.register);
  dbms_output.put_line('Binding: '||r1.binding);
--  dbms_output.put_line('Compression: '||r1.compression);
  dbms_output.put_line('Error: '||r1.err);
dbms_output.put_line('---------------------------------------------------------------------------------------');
END LOOP;
END;
/

set serveroutput on size 1000000
set lines 132
set pagesize 9999 feed off ver off trims on
DECLARE
pad10 CHAR(10) := ' ';
cursor c1 is
select thread#, low_sequence#, high_sequence# from gv\$archive_gap;

cursor c2 is
select l.thread# thread,max(r.sequence#) lr, max(l.sequence#) ls
from gv\$archived_log r, gv\$log l
where r.dest_id = 2 
and r.inst_id=r.inst_id
and r.thread#=l.thread#
and l.archived= 'YES'
group by l.thread#
order by l.thread# asc;

BEGIN

dbms_output.put_line('# ---------------------------------------------------- #');
for r1 in c2 loop
  dbms_output.put_line('Tread No.: '||r1.thread||pad10||'Last Archive Received: '||r1.lr||pad10||'Last Archive Sent: '||r1.ls);
end loop;
for r2 in c1 loop
  dbms_output.put_line('Gap Detected for thread#: '||r2.thread# ||' - ' ||'Low: '||r2.low_sequence#||' - '||'High: '||r2.high_sequence#);
end loop;
dbms_output.put_line('# ---------------------------------------------------- #');

END;
/

quit;
CDG1
cat ${dg_report}/dg_report_$dbname >> ${logs}/Alert.log
}
#########################################################
#########################################################
# Standby Database Information
#########################################################
DG_status()
{
${ECHO} CHECKING Dataguard infromation of ${ORACLE_SID} at `date`
sqlplus -s "/as sysdba" >${dg_report}/dg_status_$dbname << DG1
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
DG1
cat ${dg_report}/dg_status_$dbname >> ${logs}/Alert.log
}
####################################################
####################################################
# Database General Information
####################################################
db_info()
{
sqlplus -s "/as sysdba" >${db_info}/db_info_$dbname << DBI
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
DBI
cat ${db_info}/db_info_$dbname >> ${logs}/Alert.log
}
##################################################################
##################################################################
# RMAN Reporting for Version > 10g
##################################################################
rman_report()
{
${ECHO} CHECKING ${ORACLE_SID} at `date`
sqlplus -s "/as sysdba" >${rman_report}/rman_report_$dbname <<EOF2
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
EOF2
ALRTCNT=`cat ${rman_report}/rman_report_$dbname | wc -l`
ALRTSTA=0
if [ ${ALRTCNT} -gt ${ALRTSTA} ]; then
${ECHO} "RMAN Backup Report of $dbname" >> ${logs}/Alert.log
cat ${rman_report}/rman_report_$dbname >> ${logs}/Alert.log
else
${ECHO} "No RMAN Backup taken on $dbname" >> ${logs}/Alert.log
fi
}
##################################################################
##################################################################
# RMAN Reporting for Version < 10g
##################################################################
rman_report_cmd()
{
export NLS_DATE_FORMAT="DD/MON/YYYY hh24:mi:ss" 
rman target / <<RMA > ${rman_report}/rman_cmd_rpt.${dbname}.log
list backup summary;
list backup of archivelog from time = 'sysdate -1';
quit;
RMA
if [ ! -s ${rman_report}/rman_cmd_rpt.${dbname}.log ]; then
${ECHO} "RMAN Backup was not taken on this $dbanme" >> ${logs}/Alert.log
else
${ECHO} "RMAN Backup Report of $dbname " >> ${logs}/Alert.log
cat ${rman_report}/rman_cmd_rpt.${dbname}.log >> ${logs}/Alert.log
fi
}
####################################################################
####################################################################
# Listener Status
####################################################################
lsnrctl_status()
{
LISTENER=$1
lsnrctl status $LISTENER |grep \"${dbname} |grep READY > ${Listener_logs}/listener_status_$dbname.log
if [ $? -eq 0 ]
then
echo "LISTENER is UP" >> ${logs}/Alert.log
${ECHO} "---- The below Listener Serivces are used for database ${db_name}----- \n" >> ${logs}/Alert.log
lsnrctl status LISTENER |grep \"${dbname} |grep Service |grep READY> ${Listener_logs}/listener_$dbname.log
cat ${Listener_logs}/listener_$dbname.log >> ${logs}/Alert.log
else
echo "LISTENER is down or Running from different home or not running from defualt location" >> ${logs}/Alert.log
fi
}
####################################################################
# Directory and Log file location
####################################################################
logs=/tmp/BIAS
instance_state=${logs}/instance_state
awr_report=${logs}/awr_report
bdump_alerts=${logs}/bdump_alerts
db_role=${logs}/db_role
fs_monitor=${logs}/fs_monitor
rman_report=${logs}/rman_report
ts_monitor=${logs}/ts_monitor
asm_space=${logs}/asm_space
crs=${logs}/crs
oracle_home=${logs}/oracle_home
db_state=${logs}/db_state
db_info=${logs}/db_info
dg_report=${logs}/dg_report
misc=${logs}/misc
index_info=${logs}/index_info
Listener_logs=${logs}/Listener_logs
export ORAENV_ASK=NO
if [ -d ${logs} ]
then
rm -rf ${logs}
mkdir -p ${instance_state} ${awr_report} ${bdump_alerts} ${db_role} ${fs_monitor} ${rman_report} ${ts_monitor} ${asm_space} \
${crs} ${oracle_home} ${db_state} ${db_info} ${dg_report} ${misc} ${index_info} ${Listener_logs}
else
mkdir -p ${instance_state} ${awr_report} ${bdump_alerts} ${db_role} ${fs_monitor} ${rman_report} ${ts_monitor} ${asm_space} \
${crs} ${oracle_home} ${db_state} ${db_info} ${dg_report} ${misc} ${index_info} ${Listener_logs}
fi
scripts=/tmp
c_oratab=/tmp/c_oratab
>${logs}/mailfile
> ${logs}/Alert.log
#######################################################################
#######################################################################
# Checking the Unix Flavour and substituting few commands
#######################################################################
uname=`uname`
case ${uname} in
SunOS) AWK=nawk
ora_tab=/var/opt/oracle/oratab
;;
AIX) AWK=awk
ora_tab=/etc/oratab
;;
Linux) ora_tab=/etc/oratab
AWK=awk
;;
*) ora_tab=/etc/oratab
AWK=awk
;;
esac
case $SHELL in
*/bin/bash) ECHO="echo -e"
;;
*/bin/Bash) ECHO="echo -e"
;;
*/bin/sh) ECHO="echo -e"
;;
*) ECHO=echo
;;
esac
##########################################################################
##########################################################################
# Check for CLUSTER presence and calling functions
##########################################################################
echo $*
echo $@
Run=$1
CRS_GREP=`ps -ef |grep crsd.bin |grep -v grep`
if [ -z "${CRS_GREP}" ]
then
CRS_PRESENCE=N
echo $CRS_PRESENCE
${ECHO} "Clusterware is not installed in this server \n" >> ${logs}/Alert.log
else
CRS_PRESENCE=Y
echo $CRS_PRESENCE
fi
if [ "${CRS_PRESENCE}" = "Y" ]
then
NUM_ARGS=$(get_max `ps -ef |grep crsd.bin |grep -v grep`)
((NUM_ARGS == -1)) && echo "ERROR: get_max Function Error...Exiting....."\
                   && exit 2
ARGM2=$(((NUM_ARGS -1)))
HOSTNAME=`hostname | cut -d'.' -f1`
ps -ef |grep crsd.bin |grep -v grep | ${AWK} '{print $'$ARGM2'}' |while read CRS
do
COUNT=`echo $CRS | wc -c`
CRS_HOME_BIN=`echo $CRS | cut -c-$((${COUNT}-10))`
seperate
echo "Checking CRS Status. The crs bin path is= ${CRS_HOME_BIN}" >> ${logs}/Alert.log
divide 
sh ${CRS_HOME_BIN}/olsnodes > ${logs}/nodes
crs_stat2 $CRS_HOME_BIN | grep -i OFFLINE > ${crs}/crs.log
ALRTCRSCNT=`cat ${crs}/crs.log | wc -l`
ALRTCRSSTA=0
if [ ${ALRTCRSCNT} -gt ${ALRTCRSSTA} ]; then
${ECHO} "\nCRS issue on server `hostname`\n" >> ${logs}/Alert.log
cat ${crs}/crs.log >> ${logs}/Alert.log
else
${ECHO} "No CRS Issue \n" >> ${logs}/Alert.log
fi
done
fi
##################################################################################
#export ORAENV_ASK=NO
export user=oracle
##################################################################################
# Calling Filesystem space function
##################################################################################
seperate
divide
echo "Checking Filesystem space on server `hostname`" >> ${logs}/Alert.log
divide
CheckSpace
fdivide
echo "Checking the Network drops" >> ${logs}/Alert.log
divide
netstat_check
seperate
##################################################################################
#######################################################################################################################
# Checking the number instance currently up and looping into each individual instance and calling the necessary functions
#######################################################################################################################
Inst_cnt=`ps -ef | grep pmon | grep -v grep |wc -l`
echo "NUMBER OF ORACLE INSTANCES IN `hostname` is $Inst_cnt"
ps -ef | grep pmon | grep -v grep |grep -v ipmon | cut -d'_' -f3 > ${db_state}/database.info
## Loop 1
cat ${db_state}/database.info | while read dbname
do
${ECHO} "###################################################################"  >> ${logs}/Alert.log  
${ECHO} "##                                                                 "  >> ${logs}/Alert.log                                                         
${ECHO} "## Looking in the ORACLE INSTANCE :$dbname                         "  >> ${logs}/Alert.log  
${ECHO} "##                                                                 "  >> ${logs}/Alert.log
${ECHO} "###################################################################"  >> ${logs}/Alert.log  
if [ -s /tmp/inst_list ]
then
cat /tmp/inst_list | while read inst_name
do
if [ "$dbname" = "$inst_name" ]
then
 Cluster_instance=Y 
echo $Cluster_instance > ${db_state}/instance_state.$dbname
${ECHO} "Note: Since this database information is already collected from other node, it will not collect here. 
It will only checks alert log and pulls the last 24 hours awr report for this instance" >> ${logs}/Alert.log
break
else
  echo "skipping"
fi
done
else
Cluster_instance=N 
echo $Cluster_instance > ${db_state}/instance_state.$dbname
fi
if [ ! -s ${db_state}/instance_state.$dbname ]
then
Cluster_instance=N 
echo $Cluster_instance > ${db_state}/instance_state.$dbname
fi
Clust_inst=`cat ${db_state}/instance_state.$dbname`
###############################################################################
# Setting the environment vairable of ORACLE DATABASE following same method of .oraenv
###############################################################################
export ORACLE_SID=$dbname
if [ ${ORACLE_HOME:-0} = 0 ]; then
    OLDHOME=$PATH
else
    OLDHOME=$ORACLE_HOME
fi
## If c_oratab file found then choose it otherwise look for the default oratab
if [ -f "$c_oratab" ]; then
${ECHO} "c_oratab file is mentioned and will be consider inplace of oratab\n"
query_oratab=${c_oratab}
else
${ECHO} "c_oratab file is not mentioned, hence default oratab will be consider\n"
query_oratab=${ora_tab}
fi
cat ${query_oratab} | sed /^#/d | sed /^$/d | ${AWK} -F: \
'{print $1, $2}' | while read DBSID NEW_HOME
do
if [ "$dbname" = "$DBSID" ]
then
 echo $NEW_HOME > ${oracle_home}/ORACLE_HOME_$dbname
break
else
echo "skipping $DBSID"
fi
done
export ORACLE_HOME=`cat ${oracle_home}/ORACLE_HOME_$dbname`
if [ -z "$ORACLE_HOME" ]
then
echo " Oracle Home for Instance $dbname is missing in the oratab. Note make sure you have the instance specific enteries in oratab. 
Or if you are using /tmp/c_oratab please check it\n" >> ${logs}/Alert.log
else
#
# Reset LD_LIBRARY_PATH
#
case "$LD_LIBRARY_PATH" in
    *$OLDHOME/lib*)     LD_LIBRARY_PATH=`echo $LD_LIBRARY_PATH | \
                            sed "s;$OLDHOME/lib;$ORACLE_HOME/lib;g"` ;;
    *$ORACLE_HOME/lib*) ;;
    "")                 LD_LIBRARY_PATH=$ORACLE_HOME/lib ;;
    *)                  LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH ;;
esac

export LD_LIBRARY_PATH
#
# Put new ORACLE_HOME in path and remove old one
#
case "$OLDHOME" in
    "") OLDHOME=$PATH ;;        #This makes it so that null OLDHOME can't match
esac                            #anything in next case statement

case "$PATH" in
    *$OLDHOME/bin*)     PATH=`echo $PATH | \
                            sed "s;$OLDHOME/bin;$ORACLE_HOME/bin;g"` ;;
    *$ORACLE_HOME/bin*) ;;
    *:)                 PATH=${PATH}$ORACLE_HOME/bin: ;;
    "")                 PATH=$ORACLE_HOME/bin ;;
    *)                  PATH=$PATH:$ORACLE_HOME/bin ;;
esac

export PATH
export TNS_ADMIN=$ORACLE_HOME/network/admin
###
#export PATH=/usr/local/bin:$ORACLE_HOME/bin
#export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$LD_LIBRARY_PATH
# . oraenv
#
# Checking and logging the Database Version
#
echo "-------------DATABASE HOME :$ORACLE_HOME ----------" 
export DECIMAL_VERSION=$(sqlplus -V |sed -e 's/[a-z]//g' -e 's/[A-Z]//g' -e 's/ //g' |sed 's/[*:=-]//g' |grep -v ^$)
export NUMERIC_VERSION=$(echo $DECIMAL_VERSION |sed -e 's/\.//g')
echo "The database version is: $DECIMAL_VERSION - $NUMERIC_VERSION"
##############################
# Checking if the Instance is ASM and running ASM related functions
##############################
## Loop 11 start
if [ "$(echo $dbname | cut -c0-4)" = "+ASM" ]
then
sqlplus -s "/as sysdba"  <<AS1
set heading off head off feed off feedback off lines 500 pagesize 0
spool ${bdump_alerts}/bdump.$dbname
select value from v\$parameter where name= 'background_dump_dest';
spool off
spool ${instance_state}/instance_state.$dbname
select status from v\$instance;
spool off
spool ${asm_space}/asm_space.log
col GROUP_NUMBER format 999;
col SUBSTR(NAME,1,20) format a10
col state format a8
col type format a8
col total_mb format 9999999999
col free_mb format 9999999999
col DISK_NAME format a22
select group_number, substr(name,1,20) DISK_NAME, state, type, total_mb, 
free_mb, round((1- (DECODE(total_mb,0,0,free_mb/total_mb)))*100,0) from v\$asm_diskgroup order by 1,2;
spool off
AS1
fdivide
echo "Executing ASM Space Script" >> ${logs}/Alert.log
divide
asmspace 
fdivide
echo "Checking DB ALERT LOG of $dbname" >> ${logs}/Alert.log
divide
db_alert
seperate
##
else
###########################
# Checking the database open type, other instances name, archive destination and bdump location
###########################
sqlplus -s "/as sysdba"  <<EOF1
set linesize 200 heading off head off feed off feedback off pagesize 0
spool ${db_role}/db_role_state.$dbname
select decode(OPEN_MODE, 'READ WRITE','READ_WRITE','READ ONLY','READ_ONLY','MOUNTED','MOUNTED') open_mode, 
decode(DATABASE_ROLE,'PHYSICAL STANDBY','PHYSICAL_STANDBY','PRIMARY','PRIMARY') ROLE from v\$database;
spool off
spool ${instance_state}/instance_name.$dbname
select instance_name from gv\$instance where instance_name not in (select instance_name from v\$instance);
spool off
spool ${db_info}/db_dr_state.$dbname
select destination
from v\$archive_dest where target not in ('PRIMARY','LOCAL');
spool off
spool ${bdump_alerts}/bdump.$dbname
select value from v\$parameter where name= 'background_dump_dest';
spool off
EOF1
fi  
## Loop 11 stop
#
# Checking the Database role
#
# Loop 12 start
if [ "$Clust_inst" = "N" ]
then
# Loop 13 start
cat ${db_role}/db_role_state.$dbname | sed /^$/d  | while read mode role
do
# Loop 14 start
if [ ! -s ${db_role}/db_role_state.$dbname ]
then
echo "ERROR: No details entered" >> ${logs}/Alert.log
##############################################
# If the database is a ordinary Primary database, it runs DB_INFO,Checks presence of dataguard [if so runs PRIM_DR], Tablespace,
# RMAN_REPORT or RMAN_REPORT_CMD, GATHER_STATS_RPT, DB_ALERT, AWR_REPORT, INDEX_REBUILD, lsnrctl_status
##############################################
elif [ "$mode" = "READ_WRITE" ] && [ "$role" = "PRIMARY" ]
then
fdivide
echo "Gathering the Database information $dbname" >> ${logs}/Alert.log
divide
db_info
if [ ! -s ${db_info}/db_dr_state.$dbname ]
then
fdivide
echo "This Database don't have a Data Guard" >> ${logs}/Alert.log
divide
else
fdivide
echo "Data gaurd is available for this database $dbname" >> ${logs}/Alert.log
divide
fdivide
echo "Executing Datagaurd Configuration on Primary" >> ${logs}/Alert.log
divide
prim_dr
fi    ###### Belongs to DG Presence
fdivide
echo "Executing Tablespace Script on $dbname" >> ${logs}/Alert.log
divide
Tablespace
fdivide
echo "Checking RMAN REPORT of $dbname" >> ${logs}/Alert.log
divide
if [ "$NUMERIC_VERSION" -lt 101000 ]; then
echo "The database is in lower version ($DECIMAL_VERSION), checking via rman cmd" >> ${logs}/Alert.log
rman_report_cmd
else
rman_report
fi   ##### Loop belongs to RMAN version
fdivide
echo "Checking DB Analyzed Objects of $dbname" >> ${logs}/Alert.log
divide
gather_stats_rpt
fdivide
echo "Checking status of LISTENER" >> ${logs}/Alert.log
divide
lsnrctl_status
fdivide
echo "Checking DB ALERT LOG of $dbname" >> ${logs}/Alert.log
divide
db_alert
fdivide
echo "Checking Index Fragmentation report of $dbname" >> ${logs}/Alert.log
divide
index_rebuild
fdivide
echo "Pulling up the Report for last 24 hours, should recieve in seperate mail"  >> ${logs}/Alert.log 
divide
awr_report
seperate
########################################
# If the database is "Physical Standby" in mounted state, it runs DB_INFO, PRIM_DR, DB_ALERT
########################################
elif [ "$role" = "PHYSICAL_STANDBY" ] && [ "$mode" = "MOUNTED" ]
then
echo "$dbname is a physical standby instance on 'MOUNT' state" >> ${logs}/Alert.log
fdivide
echo "Gathering the Standby Database information $dbname" >> ${logs}/Alert.log
divide
db_info
fdivide
echo "Executing Datagaurd Configuration on Primary" >> ${logs}/Alert.log
divide
prim_dr
DG_status
fdivide
echo "Checking DB ALERT LOG of $dbname" >> ${logs}/Alert.log
divide
db_alert
seperate
##########################################
# If the database is "Physical Standby" in OPEN mode, it runs DB_INFO, PRIM_DR,RMAN_REPORT,DB_ALERT,AWR_REPORT
##########################################
elif [ "$role" = "PHYSICAL_STANDBY" ] && [ "$mode" = "OPEN_ONLY" ]
then
echo "$dbname is a physical standby instance on 'OPEN' state" >> ${logs}/Alert.log
sqlplus / 
fdivide
echo "Gathering the Standby Database information $dbname" >> ${logs}/Alert.log
divide
db_info
fdivide
echo "Executing Datagaurd Configuration on Primary" >> ${logs}/Alert.log
divide
prim_dr
DG_statusA
fdivide
echo "Checking if RMAN Backup is running for the Standby: $dbname" >> ${logs}/Alert.log
divide
rman_report
fdivide
echo "Checking DB ALERT LOG of $dbname" >> ${logs}/Alert.log
divide
db_alert
fdivide
echo "Pulling up the AWR Report for last 24 hours, should recieve in seperate mail"  >> ${logs}/Alert.log 
fdivide
awr_report
seperate
#############################################
# If the database is PRIMARY and in MOUNTED state, it runs DB_ALERT, request the dba to check the database manually
#############################################
elif [ "$mode" = "MOUNTED" ] && [ "$role" = "PRIMARY" ]
then
echo "$dbname is a primary database on mount state, please check the alert log"  >> ${logs}/Alert.log 
fdivide
echo "Checking DB ALERT LOG of $dbname" >> ${logs}/Alert.log  >> ${logs}/Alert.log 
divide
db_alert
seperate
else
fdivide
echo "Sorry Intelligent not working here for the Database: $dbname, please check it manually\n" >> ${logs}/Alert.log 
divide
seperate
fi  
## Loop 14 stop
done
## Loop 13 stop
cat ${instance_state}/instance_name.$dbname >> ${instance_state}/inst_list
else
## BUG: This is not suppose to remove right here. We are removing the file before scp
#rm -rf /tmp/inst_list
fdivide
echo "Checking DB ALERT LOG of $dbname" >> ${logs}/Alert.log
divide
db_alert
fdivide
echo "Pulling up the AWR Report for last 24 hours, should recieve in seperate mail"  >> ${logs}/Alert.log 
fdivide
awr_report
seperate
fi  
## Loop 12 stop       
fi
## Loop 11 stop
done
## Loop 1 Stop
####################################################################################################################
###############################################################
# Triggering Alert notification 
###############################################################
prepend_sub="(Daily Monitoring,`hostname`) Alert:"
output_file=${logs}/Alert.log
notify
###############################################################
###############################################################
# Running the script in other nodes if CRS is present
###############################################################
#
# Checking if the first argument running this scipt has 'no'
#
## Loop 2 start
if [ "$Run" = "no" ]
then
echo "Run is $Run"
echo "skipping checking on $node_name"
#
# If the CRS_PRESENCE is YES then search the node names and scp the file
#
elif [ ${CRS_PRESENCE} = "Y" ]
then
cat ${logs}/nodes | while read node_name
## Loop 21 start
do
echo "Run is $Run"
node_name1=`echo ${node_name} | ${AWK} -F '.' '{print $1}'`
## Loop 22 start
if [ "${node_name1}" = "$HOSTNAME" ]
then
echo "skipping this node $node_name"
else
echo "script will execute on this nodename=${node_name}"
ssh -t -t $node_name <<REMOVE
rm /tmp/test.sh
rm /tmp/inst_list
exit
REMOVE
echo "Scp the inst_list file to remote node"
scp oracle@`hostname`:${instance_state}/inst_list oracle@${node_name}:/tmp/inst_list
## $0 gives the present file command
echo "Scp this script to the remote node as /tmp/test.sh"
scp oracle@`hostname`:$0 oracle@${node_name}:/tmp/test.sh
ssh -t -t $node_name <<NON
chmod 755 /tmp/test.sh
sh /tmp/test.sh no >/tmp/test.log
exit
NON
fi
## Loop 22 stop
done
## Loop 21 stop
else
seperate
${ECHO} "Clusterware is not installed in this server so it don't have to spawn the script to other servers \n" >> ${logs}/Alert.log
divide
fi
## Loop 2 stop
##################################################################

