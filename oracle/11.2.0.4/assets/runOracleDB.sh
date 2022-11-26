#!/usr/bin/env bash

set -o errexit

source /assets/colorecho
source ~/.bashrc

alert_log="$ORACLE_BASE/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace/alert_$ORACLE_SID.log"
listener_log="$ORACLE_BASE/diag/tnslsnr/$HOSTNAME/listener/trace/listener.log"
spfile=$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora

# monitor $logfile
monitor() {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}

# SIGTERM handler
function _term() {
   echo "Stopping container."
   echo "SIGTERM received, shutting down database!"
   stop
}

start_db() {
	trap_stop_db
	echo_yellow "Starting listener..."
	monitor $listener_log listener &
	lsnrctl start | while read line; do echo -e "lsnrctl: $line"; done
	echo_yellow "Starting database..."
	monitor $alert_log alertlog &
	MON_ALERT_PID=$!
	sqlplus / as sysdba <<-EOF |
		prompt Starting with spfile...
		startup;
		alter system register;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
	for f in /oracle-initdb.d/*; do
		case "$f" in
            *.sh)     echo "$0: running $f"; . "$f" ;;
            *.sql)    echo "$0: running $f"; echo "exit" | sqlplus SYS/oracle as SYSDBA @"$f"; echo ;;
            *)        echo "$0: ignoring $f" ;;
		esac
	done
	wait $MON_ALERT_PID
}

create_db() {
	echo_yellow "Database does not exist. Creating database..."
	date "+%F %T"
	echo "START NETCA"
	monitor $listener_log listener &
	netca -silent -responsefile /install/database/response/netca.rsp
	echo_green "Listener created."
	echo "START DBCA"
	monitor $alert_log alertlog &
	MON_ALERT_PID=$!
	dbca -silent -createDatabase -responseFile /assets/dbca.rsp
	echo_green "Database created."
	date "+%F %T"
	change_datapump_dir
}

stop() {
	trap '' SIGINT SIGTERM
	db_shutdown
	echo_yellow "Shutting down listener..."
	lsnrctl stop | while read line; do echo -e "lsnrctl: $line"; done
	kill $MON_ALERT_PID
	exit 0
}

db_shutdown() {
	ps -ef | grep ora_pmon | grep -v grep > /dev/null && \
	echo_yellow "Shutting down the database..." && \
	sqlplus / as sysdba <<-EOF |
		set echo on
		shutdown immediate;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

change_datapump_dir () {
	echo_green "Changing datapump dir to /datapump"
	sqlplus / as sysdba <<-EOF |
		create or replace directory data_pump_dir as '/datapump';
		commit;
		exit 0
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}


############# MAIN ################

# Set SIGTERM handler
trap _term SIGTERM 

echo "Checking shared memory..."
df -h | grep "Mounted on" && df -h | grep -E --color "^.*/dev/shm" || echo "Shared memory is not mounted."

# Check whether container has enough memory
if [ "$(df -Pk /dev/shm | tail -n 1 | awk '{print $2}')" -lt 1048576 ]; then
   echo "Error: The system doesn't have enough memory allocated."
   echo "A database 11g needs at least 1 GB of shared memory (/dev/shm)."
   echo "You currently only have $(df -Pk /dev/shm | tail -n 1 | awk '{print $2/1024}') MB allocated to the system."
   exit 1
fi


if [ ! -f $spfile ]; then
  create_db
  stop
fi
start_db