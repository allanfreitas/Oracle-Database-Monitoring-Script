####################################################################
# Listener Status
####################################################################
lsnrctl_status()
{
local listener_name=$1
local db_name=$2
local alert_log=$3
local listener_log_dir=$4
lsnrctl status $listener_name |grep \"${dbname} |grep READY > ${listener_log_dir}/listener_status_$dbname.log
if [ $? -eq 0 ]
then
    echo "LISTENER is UP" >> ${alert_log}
    ${ECHO} "---- The below Listener Serivces are used for database ${db_name}----- \n" >> ${alert_log}
    lsnrctl status LISTENER |grep \"${dbname} |grep Service |grep READY> ${listener_log_dir}/listener_$dbname.log
    cat ${listener_log_dir}/listener_$dbname.log >> ${alert_log}
else
    echo "LISTENER is down or Running from different home or not running from defualt location" >> ${alert_log}
fi
}