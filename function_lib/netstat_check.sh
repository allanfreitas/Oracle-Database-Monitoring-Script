netstat_check()
{
local alert_log=$3
netstat -s | awk 'NF==1 {
 protocol=$0
 next}
  {match($0,"fragments dropped") || match($0,"packet receive errors") || match($0,"udpInOverflows")
if (RSTART>0) {
 printf("%s %s\n",protocol, $0)
RSTART=0
}
}
' >> "${alert_log}"
}