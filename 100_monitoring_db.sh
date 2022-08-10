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
. ${functionbasepath}send_notification.sh
. ${functionbasepath}gg_info_status.sh
. ${functionbasepath}netstat_check.sh
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

instance_state=${logfilepath}/instance_state
awr_report=${logfilepath}/awr_report
bdump_alerts=${logfilepath}/bdump_alerts
db_role=${logfilepath}/db_role
fs_monitor=${logfilepath}/fs_monitor
rman_report=${logfilepath}/rman_report
ts_monitor=${logfilepath}/ts_monitor
asm_space=${logfilepath}/asm_space
crs=${logfilepath}/crs
oracle_home=${logfilepath}/oracle_home
db_state=${logfilepath}/db_state
db_info=${logfilepath}/db_info
dg_report=${logfilepath}/dg_report
misc=${logfilepath}/misc
index_info=${logfilepath}/index_info
listener_logs=${logfilepath}/listener_logs

#
now=$(date "+%m/%d/%y %H:%M:%S")
echo $now >>$logfilepath$logfilename
#
now=$(date "+%m/%d/%y %H:%M:%S")" ====>  ########   OGG STATUS    ########"
echo $now >>$logfilepath$logfilename
#

#######################################################################
# Checking the Unix Flavour and substituting few commands
#######################################################################
uname=`uname`
case ${uname} in
SunOS) AWK=nawk
ora_tab=/var/opt/oracle/oratab
;;
AIX) AWK=awk
ora_tab=/etc/oratab
;;
Linux) ora_tab=/etc/oratab
AWK=awk
;;
*) ora_tab=/etc/oratab
AWK=awk
;;
esac
case $SHELL in
*/bin/bash) ECHO="echo -e"
;;
*/bin/Bash) ECHO="echo -e"
;;
*/bin/sh) ECHO="echo -e"
;;
*) ECHO=echo
;;
esac

netstat_check ${logfilepath}
send_notification "$trgappname"_Overlay_abend "Invalid database name for replication" ${TOADDR} ${RTNADDR} ${CCADDR}
