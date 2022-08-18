#####################################################
# Filesystem Space Check Method
#####################################################
check_space ()
{
> ${fs_monitor}/fsspace_Check.log
case ${uname} in
Linux)
    df -k | tail -n+2 |grep % | egrep -v '/mnt/cdrom|/dev/fd|/etc/mnttab|/proc|/dev/cd[0-9]' > ${fs_monitor}/fsmonitor.log
;;
*)
    df -k | tail +2 |grep % | egrep -v '/mnt/cdrom|/dev/fd|/etc/mnttab|/proc|/dev/cd[0-9]'> ${fs_monitor}/fsmonitor.log
;;
esac	
if [ ! -s ${fs_monitor}/fsmonitor.log ]
then
    echo "ERROR: Filesystem cannot be monitor, please monitor it manually" >> ${fs_monitor}/fsspace_Check.log 
fi
    cat ${fs_monitor}/fsmonitor.log | while read fsdisk 
do
echo "fsdisk = $fsdisk"
Arg2=$(echo "$fsdisk" | ${AWK} -F '%' '{print $1}')
Partition2=$(echo $fsdisk | ${AWK} -F '%' '{print $2}')
kount=$(echo $Arg2 |wc -c)
Percnt2=$(echo $Arg2 | cut -c$((${kount}-2))-$((${kount}-1)) | ${AWK} '{print $1}')
if [ "${Percnt2:-0}" -gt "${FILESYSTEM_SpaceThreshold}" ]
then
    ${ECHO} "\n The filesystem $Partition2 is ($Percnt2%) used on Server $(hostname) as of $(date)\n" >> ${fs_monitor}/fsspace_Check.log
fi
done
ALRTCNT3=$(cat ${fs_monitor}/fsspace_Check.log | wc -l)
ALRTSTA3=0
if [ "${ALRTCNT3}" -gt ${ALRTSTA3} ]; then
    echo "Filesystem Space alert on server $(hostname) and date $(date)" >> "${logs}"/Alert.log
    cat "${fs_monitor}"/fsspace_Check.log >> "${logs}"/Alert.log
else
    echo "No filesystem space issue as of $(date)" >> "${logs}"/Alert.log
fi
}