#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

if [ ! -f "/etc/oratab" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/installDB.sh
fi

su oracle -c "/assets/runOracleDB.sh"