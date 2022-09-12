#!/bin/sh
# Import properties file
#
. ./environment.properties
#################################################
# Default Configuration							#
#################################################
trgbasepath="${basepath}targets/"
logfilepath="${basepath}logs/"
functionbasepath="${basepath}function_lib/"
custfunctionbasepath="${basepath}custom_lib/"
custsqlbasepath="${custfunctionbasepath}sql/"
sqlbasepath="${functionbasepath}sql/"
rmanbasepath="${functionbasepath}rman/"
abendfile="$trgbasepath""$trgdbname"/"$trgdbname"_1000_abend_step
logfilename="$trgdbname"db_list_$(date +%a)"_$(date +%F).log"

####################################################################################################
#      add functions library                                                                       #
####################################################################################################
. ${functionbasepath}set_env_vars.sh

# Loop through each host name . . .
for line in $(grep -v '^ *#' < "${custfunctionbasepath}"103_run_sqlplus.csv)
do
  IFS=, read -r __infa_name  __host_name __db_list __db_home <<< "$line"
  echo " "
  echo "************************"
  echo "Environment: $__infa_name"
  echo "$__host_name"
  echo "************************"
  if [ "$__db_list" = "*" ];
  then
    db_list=$(ssh -n "$__host_name" "cat ${ora_tab}|egrep ':N|:Y'|grep -v ^[#+-]|\
            cut -f1 -d':'")
  else
    db_list="$__db_list";
  fi
  # Loop through each database name on the host
  for db in $db_list
  do
    if [ -z "$__db_home" ];
    then 
      db_home=$(ssh -n "$__host_name" "cat ${ora_tab}|egrep ':N|:Y'|grep -v ^[#+-]|\
      grep ${db}|cut -f2 -d':'")
      #echo "$db_home"
    else
      db_home="$__db_home";
    fi
    if [ -z "$db_home" ];
    then
      echo "DB Home for DB ${__db_home} is not deterermined from oratab"
      exit 123
    fi
    echo "************************"
    echo "connected to database $db"
    echo "************************"
    ssh "$__host_name" "
      ORACLE_SID=${db}; export ORACLE_SID;
      ORACLE_HOME=${db_home}; export ORACLE_HOME;
      ${db_home}/bin/sqlplus -s '/as sysdba'
    "
  done
done