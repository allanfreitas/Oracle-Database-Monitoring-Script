db_alert()
{
    dbname=$1
    bdump_dir=$2
    logs_dir=$3
    echo CHECKING DB Alert of ${ORACLE_SID} at $(date)
    export alrt_loc=$(cat ${bdump_dir}/bdump.$dbname |grep bdump |${AWK} '{print $1}')
    if [ -z "$alrt_loc" ]
    then
        export alrt_loc=$(cat ${bdump_dir}/bdump.$dbname |grep trace |${AWK} '{print $1}')
        echo "New Alert Location" 
    fi
    ${ECHO} "~~~~~~~~~~~ALERT LOCATION : $alrt_loc ~~~~~~~~~~~~\n" >> ${logs_dir}/Alert.log
#DATE="`date +%y/%m/%d`"
#YEAR="`date +%y -d last-week`"
#MONTH="`date +%h -d last-week`"
#DAY="`date +%d -d last-week`"
#WEEK="`date +%a -d last-week`"
#cat -n ${alrt_loc}/alert_$dbname.log |grep "$YEAR" |grep "$MONTH " |grep " $DAY " |grep $WEEK > ${bdump_dir}/alrt_st_$dbname.log
#export ST=`head -1 ${bdump_dir}/alrt_st_$dbname.log |cut -f1`
#if [ -z "$ST" ]
#then
tail -${alert_pointer} ${alrt_loc}/alert_${dbname}.log >> ${bdump_dir}/TruncAlert7_$dbname.log
#else
#tail -n +$ST ${alrt_loc}/alert_${dbname}.log >> ${bdump_dir}/TruncAlert7_$dbname.log
#fi
${AWK} 'NF==5 && ($1=="Mon" || $1=="Tue" || $1=="Wed" || $1=="Thu" || \
                $1=="Fri" || $1=="Sat" || $1=="Sun"){
        Date=$0
        ErrCnt=0
        next}
        {match($0,"ORA-")
                if (RSTART>0) {
                        ErrCnt++
                        printf("%d:%s: %s\n", ErrCnt,Date,$0)
                        RSTART=0
                }
        }
        ' ${bdump_dir}/TruncAlert7_$dbname.log > ${bdump_dir}/Ora_alert_${dbname}.log
ALRTCNT=$(cat ${bdump_dir}/Ora_alert_${dbname}.log | wc -l)
ALRTSTA=0
if [ ${ALRTCNT} -gt ${ALRTSTA} ]; then
    ${ECHO} "\nTotal ORA Alerts count ${ALRTCNT}\n" >> ${logs_dir}/Alert.log
    cat ${bdump_dir}/Ora_alert_${dbname}.log >> ${logs_dir}/Alert.log
else
    ${ECHO} "No DB ALERTS\n" >> ${logs_dir}/Alert.log
fi
}