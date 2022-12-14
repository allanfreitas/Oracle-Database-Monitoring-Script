db_size()
{
  local __db_home=$1
  local __resultvar=$3

  local __sql_output
  __sql_output=$(${__db_home}/bin/sqlplus -silent /" as sysdba" <<EOF
SET LINESIZE 200
SET PAGESIZE 200
COL "Database Size" FORMAT a18
COL "Used Space" FORMAT a18
COL "Used in %" FORMAT a11
COL "Free in %" FORMAT a11
COL "Database Name" FORMAT a18
COL "Free Space" FORMAT a16
COL "Growth DAY" FORMAT a11
COL "Growth WEEK" FORMAT a12
COL "Growth DAY in %" FORMAT a16
COL "Growth WEEK in %" FORMAT a16
SELECT
(select min(creation_time) from v\$datafile) "Create Time",
(select name from v\$database) "Database Name",
ROUND((SUM(USED.BYTES)/1024/1024 ),2) || ' MB' "Database Size",
ROUND((SUM(USED.BYTES)/1024/1024 )-ROUND(FREE.P/1024/1024 ),2) || ' MB' "Used Space",
ROUND(((SUM(USED.BYTES)/1024/1024 )-(FREE.P/1024/1024 ))/ROUND(SUM(USED.BYTES)/1024/1024 ,2)*100,2) || '% MB' "Used in %",
--ROUND((FREE.P/1024/1024 ),2) || ' MB' "Free Space",
--ROUND(((SUM(USED.BYTES)/1024/1024 )-((SUM(USED.BYTES)/1024/1024 )-ROUND(FREE.P/1024/1024 )))/ROUND(SUM(USED.BYTES)/1024/1024,2 )*100,2) || '% MB' "Free in %",
--ROUND(((SUM(USED.BYTES)/1024/1024 )-(FREE.P/1024/1024 ))/(select sysdate-min(creation_time) from v\$datafile),2) || ' MB' "Growth DAY",
--ROUND(((SUM(USED.BYTES)/1024/1024 )-(FREE.P/1024/1024 ))/(select sysdate-min(creation_time) from v\$datafile)/ROUND((SUM(USED.BYTES)/1024/1024 ),2)*100,3) || '% MB' "Growth DAY in %",
ROUND(((SUM(USED.BYTES)/1024/1024 )-(FREE.P/1024/1024 ))/(select sysdate-min(creation_time) from v\$datafile)*30,2) || ' MB' "Growth MONTH",
ROUND((((SUM(USED.BYTES)/1024/1024 )-(FREE.P/1024/1024 ))/(select sysdate-min(creation_time) from v\$datafile)/ROUND((SUM(USED.BYTES) /1024/1024),2)*100)*30,3) || '% MB' "Growth MONTH in %"
FROM    (SELECT BYTES FROM V\$DATAFILE
UNION ALL
SELECT BYTES FROM V\$TEMPFILE
UNION ALL
SELECT BYTES FROM V\$LOG) USED,
(SELECT SUM(BYTES) AS P FROM DBA_FREE_SPACE) FREE
GROUP BY FREE.P
/
quit;
EOF
)

  if [[ "$__resultvar" ]]; then
      eval "$__resultvar"="'$__sql_output'"
  else
      echo "$__sql_output"
  fi
}
