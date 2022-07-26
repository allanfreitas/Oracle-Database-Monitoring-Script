#################################################
# Default Configuration							#
#################################################
set -x
basepath="/Users/veeramarni/Documents/script/MONITORING_SCRIPTS/"
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
. ${functionbasepath}/mongo_db_list.sh
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
myfn () {  ls -l; }
for server in $(cat ${custfunctionbasepath}ogg_host_list.txt); do
    (ssh ${server} "$(typeset -f gg_info_status); gg_info_status gg") >> $logfilepath$logfilename
    rcode=$?
    if [ $rcode -ne 0 ]
    then
        now=$(date "+%m/%d/%y %H:%M:%S")" ====> "$server" ogg check FAILED. Abort!! RC=$rcode"
        echo $now >>$logfilepath$logfilename
    fi
done
cat $logfilepath$logfilename
