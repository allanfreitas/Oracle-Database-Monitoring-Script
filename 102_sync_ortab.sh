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
pslist=""`ps -ef  | grep -v grep | grep pmon`"


# Loop through each host name . . .
for host in `cat ${custfunctionbasepath}201_list_database.txt|sort -u`
do
  echo " "
  echo "************************"
  echo "$host"
  echo "************************"
  # Loop through each database name on the host /etc/oratab . . .
  for db in  `ssh $host "$pslist

done