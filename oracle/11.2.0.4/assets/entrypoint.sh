#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

/assets/setup.sh

if [ ! -f "/etc/oratab" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/runInstallDB.sh
fi

su oracle -c "/assets/runOracleDB.sh"