#!/bin/bash
#
####################################################################################################
#                S T A G I N G    O V E R L A Y - Source Database Tasks                            #
#                           1000_source_processing.sh
####################################################################################################
#
# Import properties file
#
. clone_environment.properties
#################################################
# Default Configuration							#
#################################################
set -x
trgbasepath="${basepath}targets/"
logfilepath="${basepath}logs/"
functionbasepath="${basepath}function_lib/"
custfunctionbasepath="${basepath}custom_lib/"
custsqlbasepath="${custfunctionbasepath}sql/"
sqlbasepath="${functionbasepath}sql/"
rmanbasepath="${functionbasepath}rman/"
abendfile="$trgbasepath""$trgdbname"/"$trgdbname"_1000_abend_step
logfilename="$trgdbname"_ogg_status$(date +%a)"_$(date +%F).log"

####################################################################################################
#      add functions library                                                                       #
####################################################################################################
. ${functionbasepath}os_verify_or_make_directory.sh
. ${functionbasepath}mongo_db_list.sh
. ${functionbasepath}/send_notification.sh
. ${functionbasepath}/gg_info_status.sh
#

#
# Check user  
#
# os_user_check ${dbosuser}
# 	rcode=$?
# 	if [ "$rcode" -gt 0 ]
# 	then
# 		error_notification_exit $rcode "Wrong os user, user should be ${dbosuser}!!" $trgdbname 0  $LINENO
# 	fi
#
# Validate Directory
#
os_verify_or_make_directory ${logfilepath}
os_verify_or_make_directory ${trgbasepath}
os_verify_or_make_directory ${trgbasepath}${trgdbname}
#os_verify_or_make_file ${abendfile} 0

#
now=$(date "+%m/%d/%y %H:%M:%S")
echo $now >>$logfilepath$logfilename
#
now=$(date "+%m/%d/%y %H:%M:%S")" ====>  ########   OGG STATUS    ########"
echo $now >>$logfilepath$logfilename
#
while IFS=, read -r __host_name __gi_home_path __db_home_path ; do
    (ssh ${__host_name} "$(typeset -f gg_info_status); gg_info_status $__gi_home_path $__db_home_path ") >> $logfilepath$logfilename
    rcode=$?
    if [ $rcode -ne 0 ]
    then
        now=$(date "+%m/%d/%y %H:%M:%S")" ====> "$server" ogg check FAILED. Abort!! RC=$rcode"
        echo $now >>$logfilepath$logfilename
    fi
done < ${custfunctionbasepath}ogg_host_list.txt
send_notification "$trgappname"_Overlay_abend "Invalid database name for replication" ${TOADDR} ${RTNADDR} ${CCADDR}
