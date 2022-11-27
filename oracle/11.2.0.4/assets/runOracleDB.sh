#!/usr/bin/env bash

set -o errexit

source /assets/colorecho
source ~/.bashrc

alert_log="$ORACLE_BASE/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
spfile=$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}

# SIGINT handler
function _int() {
   echo "Stopping container."
   echo "SIGINT received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

# SIGTERM handler
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

startDB() {
	echo_yellow "Starting listener..."
	lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
	echo_yellow "Starting database..."
	sqlplus / as sysdba <<-EOF |
		prompt Starting with spfile...
		startup;
		alter system register;
		exit;
	EOF
	while read line; do echo -e "sqlplus: $line"; done
	for f in /oracle-initdb.d/*; do
		case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; echo "exit" | sqlplus SYS/oracle as SYSDBA @"$f"; echo ;;
            *)        echo "$0: ignoring $f" ;;
		esac
	done
}

createDB() {
	echo_yellow "Database does not exist. Creating database..."
	date "+%F %T"
	echo "START NETCA"
	netca -silent -responsefile /install/database/response/netca.rsp
	echo_green "Listener created."
	echo "START DBCA"
	dbca -silent -createDatabase -responseFile /assets/dbca.rsp
	echo_green "Database created."
	date "+%F %T"
	setDatapumpDir
}


setDatapumpDir () {
	echo_green "Changing datapump dir to /datapump"
	sqlplus / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '/datapump';
		commit;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}


# MAIN
# Set SIGTERM SIGINT handler
trap _term SIGTERM 
trap _int SIGINT

# Check whether container has enough memory
echo "Checking shared memory..."
if [ "$(df -Pk /dev/shm | tail -n 1 | awk '{print $2}')" -lt 0 ]; then
   echo "Error: The system doesn't have enough memory allocated."
   exit 1
fi

monitor $alert_log alertlog &
MON_ALERT_PID=$!

if [ ! -f $spfile ]; then
  createDB
else
  startDB
fi

wait $MON_ALERT_PID