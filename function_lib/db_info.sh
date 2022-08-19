db_info()
{
  local __db_home=$1
  local __resultvar=$3

  local __sql_output
  __sql_output=$(${__db_home}/bin/sqlplus -silent /" as sysdba" <<EOF
set pages 0 lines 5000 trims on head off feed off ver off
select '"DB Name": "'||d.name ||'",'||chr(10)||
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
  '"DB or PDBs": "'||ic.pdb_info||'",'
    from V\$DATABASE d, V\$VERSION v, 
    (select LISTAGG(host_name, '\n')  within group (order by host_name) as hosts from gv\$instance) i,
    (select  LISTAGG(pdb_info, '\n') within group (order by pdb_info) as pdb_info
from  (
select c.name ||
  ' ('||c.open_mode ||')'||
  ', v' || regexp_substr(v.banner,'\d+(\.\d)+') ||
  ', size: '|| trunc(c.TOTAL_SIZE/1024/1024/1024,2) ||' GB' as pdb_info
    from V\$CONTAINERS c, V\$VERSION v, V\$DATABASE d
  where v.banner like '%Oracle Database%'
  order by c.CON_ID)) ic
  where v.banner like '%Oracle Database%'
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
