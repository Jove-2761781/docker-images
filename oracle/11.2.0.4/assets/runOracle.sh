#!/usr/bin/env bash

set -o errexit

source /assets/colorecho
source ~/.bashrc

alert_log="$ORACLE_BASE/diag/rdbms/$ORACLE_SID/$ORACLE_SID/trace/alert_$ORACLE_SID.log"

# monitor $logfile
monitor () {
    tail -F -n 0 $1 | while read line; do echo -e "$2: $line"; done
}

# SIGINT handler
function _int () {
   echo "Stopping container."
   echo "SIGINT received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

# SIGTERM handler
function _term () {
   echo "Stopping container."
   echo "SIGTERM received, shutting down database!"
   sqlplus / as sysdba <<EOF
   shutdown immediate;
   exit;
EOF
   lsnrctl stop
}

startDB () {
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


# MAIN
# Set SIGTERM SIGINT handler
trap _term SIGTERM 
trap _int SIGINT

monitor $alert_log alertlog &
MON_ALERT_PID=$!

if [ $(ps -ef | grep [o]ra_ | wc -l) -lt 1 ]; then
   echo_yellow "Instance is not runing, starting now!"
   startDB
fi

wait $MON_ALERT_PID