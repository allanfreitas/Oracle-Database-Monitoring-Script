#################################################
# Default Configuration							#
#################################################
basepath="/Users/veeramarni/Documents/script/MONITORING_SCRIPTS/"
trgbasepath="${basepath}targets/"
logfilepath="${basepath}logs/"
functionbasepath="${basepath}function_lib/"
custfunctionbasepath="${basepath}custom_lib/"
custsqlbasepath="${custfunctionbasepath}sql/"
sqlbasepath="${functionbasepath}sql/"
rmanbasepath="${functionbasepath}rman/"
abendfile="$trgbasepath""$trgdbname"/"$trgdbname"_1000_abend_step
logfilename="$trgdbname"_mongo_db_list$(date +%a)"_$(date +%F).log"

####################################################################################################
#      add functions library                                                                       #
####################################################################################################
. ${functionbasepath}os_verify_or_make_directory.sh
. ${functionbasepath}mongo_db_list.sh
. ${functionbasepath}dummy_func.sh
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
now=$(date "+%m/%d/%y %H:%M:%S")" ====>  ########   MONGO DB LIST    ########"
echo $now >>$logfilepath$logfilename
#
# mongo_db_list /usr/local/bin
while IFS=, read -r __host_name __home_path ; do
printf '%s is the package manager for %s\n' "$__host_name" "$__home_path"
    # mongo_db_list $__home_path >> $logfilepath$logfilename
    echo "" |  (ssh ${__host_name} "$(typeset -f mongo_db_list); mongo_db_list $__home_path ") >> $logfilepath$logfilename
    # echo "" | ssh ${__host_name} "uname"
    rcode=$?
    if [ $rcode -ne 0 ]
    then
        now=$(date "+%m/%d/%y %H:%M:%S")" ====> "$__host_name" mongo check FAILED. Abort!! RC=$rcode"
        echo $now >>$logfilepath$logfilename
    fi
done < ${custfunctionbasepath}mongo_host_list.txt
