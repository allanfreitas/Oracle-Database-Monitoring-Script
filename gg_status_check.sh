#!/bin/bash
EMAIL_LIST="support@dbaclass.com"

OIFS=$IFS
IFS="
"
NIFS=$IFS

function status {
    OUTPUT=`$GG_HOME/ggsci << EOF
    info all
    exit
EOF`
}
function alert {
for line in $OUTPUT
do
if [[ $(echo "${line}"|egrep 'STOP|ABEND' >/dev/null;echo $?) = 0 ]]
then
GNAME=$(echo "${line}" | awk -F" " '{print $3}')
GSTAT=$(echo "${line}" | awk -F" " '{print $2}')
GTYPE=$(echo "${line}" | awk -F" " '{print $1}')
case $GTYPE in
"MANAGER")
cat $GG_HOME/dirrpt/MGR.rpt | mailx -s "${HOSTNAME} - GoldenGate ${GTYPE} ${GSTAT}" $NOTIFY ;;

"EXTRACT"|"REPLICAT")
cat $GG_HOME/dirrpt/"${GNAME}".rpt |mailx -s "${HOSTNAME} - GoldenGate ${GTYPE} ${GNAME} ${GSTAT}" $EMAIL_LIST ;;
esac
fi
done
}
