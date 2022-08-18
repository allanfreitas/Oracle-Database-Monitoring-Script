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
# Loop through each host name . . .
for line in $(grep -v '^ *#' < "${custfunctionbasepath}"201_list_database.txt)
do
  echo " "
  echo "************************"
  echo "$line"
  echo "************************"
  # host=`echo "$line"|awk -F"," '{print $1}'`
  # __db_name=`echo "$line"|awk -F"," '{print $2}'`
  # __db_home=`echo "$line"|awk -F"," '{print $3}'`
  IFS=, read -r host __db_name __dh_home <<< "$line"
  echo "$host"
  # Loop through each database name on the host /etc/oratab . . .
  for db in $(ssh $host "cat /etc/oratab|egrep ':N|:Y'|grep -v ^[#+-]|\
  cut -f1 -d':'")
  do
     # Get the ORACLE_HOME for each database
     home=$(ssh $host "cat /etc/oratab|egrep ':N|:Y'|grep -v ^[#+-]|\
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