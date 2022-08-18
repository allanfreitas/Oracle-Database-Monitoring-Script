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
# Loop through each host name . . .
for line in $(grep -v '^ *#' < "${custfunctionbasepath}"103_run_sqlplus.csv)
do
  IFS=, read -r __host_name __db_name __db_home <<< "$line"
  echo " "
  echo "************************"
  echo "$__host_name"
  echo "************************"
  # Loop through each database name on the host /etc/oratab . . .
    # Get the ORACLE_HOME for each database
    if [ -z "$__db_home" ];
    then 
      home=$(ssh -n "$__host_name" "cat /etc/oratab|egrep ':N|:Y'|grep -v ^[#+-]|\
      grep ${__db_name}|cut -f2 -d':'")
      echo "$home"
    else
      home=__db_home;
    fi
    if [ -z "$home" ];
    then
      echo "DB Home for DB ${__db_home} is not deterermined from oratab"
      exit 123
    fi
    echo "************************"
    echo "connected to database $__db_name"
    echo "************************"
    ssh "$__host_name" "
      ORACLE_SID=${__db_name}; export ORACLE_SID;
      ORACLE_HOME=${home}; export ORACLE_HOME;
      ${home}/bin/sqlplus -s '/as sysdba'
    "
done