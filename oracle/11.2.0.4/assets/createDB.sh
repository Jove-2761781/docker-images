#!/usr/bin/env bash

set -e

source /assets/colorecho
source ~/.bashrc

createDB () {
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
		exit;
	EOF
	while read line; do echo -e "sqlplus: $line"; done
}

# Check whether container has enough memory
echo "Checking shared memory..."
if [ "$(df -Pk /dev/shm | tail -n 1 | awk '{print $2}')" -lt 0 ]; then
   echo "Error: The system doesn't have enough memory allocated."
   exit 1
fi

createDB