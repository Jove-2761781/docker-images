#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

if [ ! -d "/install/database" ]; then
	echo_red "Installation files not found. Unzip installation files into mounted(/install) folder"
	exit 1
fi

echo_yellow "Installing Oracle Database 11g"

su oracle -c "/install/database/runInstaller -silent -ignorePrereq -waitforcompletion -responseFile /assets/db_install.rsp"
$ORACLE_INVENTORY/orainstRoot.sh
$ORACLE_HOME/root.sh