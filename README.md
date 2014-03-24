  PURPOSE	:Checks Filessytem space,ASM space, Listener,Tablespace,CRS_STAT, RMAN Backups, Index Fragmentation, Gather Stats, Alert Log, 
          	pulls AWR Report(last 24hours),(MRP,Archive gap,Archive apply lag)Standby etc
  
  PLATFORM	:SunOS,HP-UX,AIX and Linux 
 
  ORACLE DB Version	: Works fine with all versions >10.1. Certain functionality will dont work in 9i. Not compatible with any version < 9i
  
  
  How to Run?	:1. Run the script with full path from any location (for example "/home/oracle/daily_monitoring.sh" and enter)
 		 2. You can edit the threshold values/email recipient address as mention in below Sub-heading.
 		 3. The exact entries of INSTANCE NAME should be presend in default "oratab" or you can create /tmp/c_oratab and add the instance name
 		    and oracle home in the formate of "<INSTANCE_NAME>:<INSTANCE_HOME>:[Y|N]". The script will first look for /tmp/c_oratab if it is  
 		    not present it will consider default ORATAB.
 
  If crs is present?	: Run this script from any one node, it will capture all the Database Instances information from that node and 
 			it will automatically spawn in other nodes to gather the alert information and space information.
 			
  
 
  NOTE		:Make sure to open this file in notepad with max size while copying it to the VI Editor. Sometimes when copying from notepad to vi editor 
                few long lines in the script may breaks and throws error when running. Figure out the broken lines and modify as needed.
 		It works well if you copy it from any  widescreen laptop/monitor.
 		
        
 
 
  AUTHOR	: Veera Srikanth Marni
  REV DATE	:06/02/2011
  REV		:1.1.1
