#!/bin/sh
# Import properties file
#
#set -x
. ./environment.properties
#################################################
# Default Configuration                                                 #
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
. ${functionbasepath}db_info.sh
. ${functionbasepath}running_jobs.sh
. ${functionbasepath}tablespace_alert.sh
. ${functionbasepath}blocking_sessions.sh
. ${functionbasepath}active_sessions.sh
. ${functionbasepath}check_db_mode.sh
. ${functionbasepath}rman_backup_status.sh

echo [
# Loop through each host name . . .
grep -v '^ *#' < "${custfunctionbasepath}"250_db_daily_checks.csv | while IFS=, read -r __infa_name __host_name __db_list __db_home
do
  #echo " "
  #echo "************************"
  #echo "$__host_name"
  #echo "************************"
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
    # Get the ORACLE_HOME for each database
    if [ -z "$__db_home" ];
    then
      db_home=$(ssh -n "$__host_name" "cat ${ora_tab}|egrep ':N|:Y'|grep -v ^[#+-]|\
      grep -w ${db}|cut -f2 -d':'")
      #echo "inside for"
        #echo "$db"
        #echo "$db_home"
    else
      db_home="$__db_home";
    fi
    if [ -z "$db_home" ];
    then
      echo "DB Home for DB ${__db_home} is not deterermined from oratab"
      exit 123
    fi
    #echo "************************"
    #echo "connected to database $db"
    #echo "************************"
    echo "{"
    echo "\"Infra name\": \"${__infa_name}\","
    smon=$(ssh -n "$__host_name" "ps -ef | grep -v grep | grep -w ora_smon_${db} | wc -l")
    smonp=$(ssh -n "$__host_name" "ps -ef | grep -v grep | grep -w ora_smon_${db}")
#echo "smon=$smon"
#echo "smonp=$smonp"

if [ "$smon" == "1" ];then

        db_mode()
        {
                ssh -n "$__host_name" "
                $(typeset -f check_db_mode);
                ORACLE_SID=${db}; export ORACLE_SID;
                ORACLE_HOME=${db_home}; export ORACLE_HOME;
                check_db_mode ${db_home};
                "
        }
        open_mode=`db_mode`;
                #echo "DM=${open_mode}";

                ssh -n "$__host_name"  "
                $(typeset -f db_info);
                $(typeset -f running_jobs);
                $(typeset -f tablespace_alert);
                $(typeset -f blocking_sessions);
                $(typeset -f active_sessions);
                $(typeset -f check_db_mode);
                $(typeset -f rman_backup_status);

                ORACLE_SID=${db}; export ORACLE_SID;
                        #echo "db_home=${db_home}"
                        #echo "SID=$ORACLE_SID"
                ORACLE_HOME=${db_home}; export ORACLE_HOME;
                        #echo "OHOME=$ORACLE_HOME"
                echo '\"DB Home\": \"${db_home}\",'
                echo '\"DB SID \": \"${db}\",'
                        #smon=$(ps -ef | grep -v grep | grep smon | grep ${db} | wc -l)
                        #echo "smon=$smon"
                        #echo "Inside main"
                        #check_db_mode ${db_home}
                        #echo $dm
                db_info ${db_home};
                        #echo ${db_mode};
                        #test="READ WRITE";
                        #if [[ $(echo "\"${open_mode}\"") == $(echo "\"READ WRITE\"") ]]
                if [[ \"${open_mode}\" == \"READ WRITE\" ]]
                then
                        running_jobs ${db_home};
                        tablespace_alert ${db_home};
                        blocking_sessions ${db_home};
                        active_sessions ${db_home};
                        rman_backup_status ${db_home};
                else
                        echo '\"Database ${db} Mode\": \"${open_mode}\",';
                fi

    "
else
        echo "\"Database ${db}\": \"Not Running\","
fi
                #echo "\"DB Home\": \"${db_home}\","
        echo "},"
  done
done
echo ]