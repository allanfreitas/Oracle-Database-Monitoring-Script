#################################################
# Default Configuration							#
#################################################
basepath="/tmp"
trgbasepath="${basepath}targets/"
logfilepath="${basepath}logs/"
functionbasepath="${basepath}function_lib/"
custfunctionbasepath="${basepath}custom_lib/"
custsqlbasepath="${custfunctionbasepath}sql/"
sqlbasepath="${functionbasepath}sql/"
rmanbasepath="${functionbasepath}rman/"

####################################################################################################
#      add functions library                                                                       #
####################################################################################################
. ${functionbasepath}/dummy_func.sh
#

#
# Check user  
#
os_user_check ${dbosuser}
	rcode=$?
	if [ "$rcode" -gt 0 ]
	then
		error_notification_exit $rcode "Wrong os user, user should be ${dbosuser}!!" $trgdbname 0  $LINENO
	fi
#

#
now=$(date "+%m/%d/%y %H:%M:%S")
echo $now >>$logfilepath$logfilename
#
now=$(date "+%m/%d/%y %H:%M:%S")" ====>  ########   OGG STATUS    ########"
echo $now >>$logfilepath$logfilename
#

gg_info_status result
echo $result
result4=$(gg_info_status)
echo $result4