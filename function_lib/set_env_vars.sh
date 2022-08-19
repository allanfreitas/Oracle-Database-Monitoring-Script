case $(uname) in
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