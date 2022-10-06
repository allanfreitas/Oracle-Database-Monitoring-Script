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
. ${functionbasepath}check_db_mode.sh

echo "["

# Loop through each host name . . .
grep -v '^ *#' < "${custfunctionbasepath}"db_status_check.csv | while IFS=, read -r __infa_name __host_name __db_list __db_home
do

        if [ "$__db_list" = "*" ];
        then
                db_list=$(ssh -n -q "$__host_name" "cat ${ora_tab}|egrep ':N|:Y'|grep -v ^[#+-]|\
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
                        db_home=$(ssh -n -q "$__host_name" "cat ${ora_tab}|egrep ':N|:Y'|grep -v ^[#+-]| grep -w ${db}|cut -f2 -d':'")
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
                        echo "\"Infra Name\" : \"${__infa_name}\",";
                        echo "\"Host Name\" : \"${__host_name}\",";
                        echo "\"Database Home\" : \"${db_home}\",";
                        echo "\"Database SID\" : \"${db}\",";
                        smon=$(ssh -n -q "$__host_name" "ps -ef | grep -v grep | grep -w ora_smon_${db} | wc -l")
                        smonp=$(ssh -n -q "$__host_name" "ps -ef | grep -v grep | grep -w ora_smon_${db}")
                        #echo "smon=$smon"
                        #echo "smonp=$smonp"

                        if [ "$smon" == "1" ];then

                                db_mode()
                                {
                                        ssh -n -q "$__host_name" "
                                        $(typeset -f check_db_mode);
                                        ORACLE_SID=${db}; export ORACLE_SID;
                                        ORACLE_HOME=${db_home}; export ORACLE_HOME;
                                        check_db_mode ${db_home};
                                        "
                                }

                                open_mode=`db_mode`;

                                echo "\"Status\" : \"Running (${open_mode})\",";
                        else
                                echo "\"Status\": \"Not Running\","
                        fi
                echo "},"
        done
done

echo "]"
