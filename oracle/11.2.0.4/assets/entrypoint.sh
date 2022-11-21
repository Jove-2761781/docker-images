#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

if [ ! -d "/u01/app/oracle/product/11.2.0/db_1" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/install.sh
fi

su oracle -c "/assets/entrypoint_oracle.sh"