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
                        db_home=$(ssh -n -q "$__host_name" "cat ${ora_tab}|egrep ':N|:Y'|grep -v ^[#+-]|\
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
                        echo "\"Infra Name\" : \"${__infa_name}\",";
                        echo "\"Host Name\" : \"${__host_name}\",";
                        echo "\"Database Home\" : \"${db_home}\",";
                        echo "\"Database SID\" : \"${db}\",";

                        check_db_status()
                        (
                                smon=$(ssh -n -q "${1}" "ps -ef | grep -v grep | grep -w ora_smon_${2} | wc -l")
                                smonp=$(ssh -n -q "${1}" "ps -ef | grep -v grep | grep -w ora_smon_${2}")
                                #echo "smon=$smon"
                                #echo "smonp=$smonp"
                        }

                        db_mode()
                        {
                                #host_server=$1;
                                #db_sid=$2;
                                #o_home=$3;
                                ssh -n -q "${1}" "
                                $(typeset -f check_db_mode);
                                ORACLE_SID=${2}; export ORACLE_SID;
                                ORACLE_HOME=${3}; export ORACLE_HOME;
                                check_db_mode ${3};
                                "
                        }

start_db()
{
ssh -n -q "${1}" "
ORACLE_SID=${2}; export ORACLE_SID;
ORACLE_HOME=${3}; export ORACLE_HOME;
${3}/bin/sqlplus -silent / as sysdba <<EOF
startppp;
exit
EOF
"
}

                        check_db_status "${__host_name}" "${db}"

                        if [ "$smon" == "1" ];then

                                echo "Database ${db} Is Alredy Running. . ."

                                open_mode=`db_mode "${__host_name}" "${db}" "${db_home}"`

                                #{
                                #       ssh -n -q "$__host_name"
                                #       "
                                #       $(typeset -f check_db_mode);
                                #       ORACLE_SID=${db}; export ORACLE_SID;
                                #       ORACLE_HOME=${db_home}; export ORACLE_HOME;
                                #       check_db_mode ${db_home};
                                #       "
                                #}

                                #open_mode=`db_mode`;

                                echo "Running In Mode : ${open_mode}";
                        else
                                echo "Database ${db} Is Not Running!!!"
                                echo "Starting Database ${db}...."

                                start_db "${__host_name}" "${db}" "${db_home}"

                                check_db_status "${__host_name}" "${db}"

                                        if [ "$smon" == "1" ];then

                                                echo "Database ${db} Started Successfully..."
                                                open_mode=`db_mode "${__host_name}" "${db}" "${db_home}"`
                                                echo "After Startup, Running In Mode : ${open_mode}";
                                        else
                                                echo "Error In Starting Database ${db}!!!"
                                                echo "Please Check"
                                                echo "Continuing For Remaining Databases...."
                                        fi

                        fi


                echo "},"

        done

done

echo "]"