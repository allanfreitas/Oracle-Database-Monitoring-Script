#
# Import properties file
#
. environment.properties
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
# Loop through each host name. Use for loop instead of while loop to interact with sqlplus
for line in $(grep -v '^ *#' < "${custfunctionbasepath}"103_remote_sqlplus.csv)
do
  IFS=, read -r host <<< "$line"
  echo " "
  echo "************************"
  echo "$host"
  echo "************************"
  # Loop through each database name on the host /etc/oratab . . .
  for db in $(ssh "$host" "cat /etc/oratab|egrep ':N|:Y'|grep -v ^[#+-]|\
  cut -f1 -d':'")
  do
     # Get the ORACLE_HOME for each database
     home=$(ssh -n "$host" "cat /etc/oratab|egrep ':N|:Y'|grep -v ^[#+-]|\
     grep ${db}|cut -f2 -d':'")
        echo "************************"
        echo "database is $db"
        echo "************************"
        ssh "$host" "
        ORACLE_SID=${db}; export ORACLE_SID;
        ORACLE_HOME=${home}; export ORACLE_HOME;
        ${home}/bin/sqlplus -s '/as sysdba'
    "
  done
done