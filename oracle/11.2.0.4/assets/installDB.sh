#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

modify_installRSP () {
	sed -i "s|#ORACLE_HOSTNAME#|$HOSTNAME|" /assets/db_install.rsp
	sed -i "s|#ORACLE_BASE#|$ORACLE_BASE|" /assets/db_install.rsp
	sed -i "s|#ORACLE_HOME#|$ORACLE_HOME|" /assets/db_install.rsp
	sed -i "s|#ORACLE_INVENTORY#|$ORACLE_INVENTORY|" /assets/db_install.rsp
}

if [ ! -d "/install/database" ]; then
	echo_red "Installation files not found. Unzip installation files into mounted(/install) folder"
	exit 1
fi

echo_yellow "Installing Oracle Database 11g"

modify_installRSP
su oracle -c "/install/database/runInstaller -silent -ignorePrereq -waitforcompletion -responseFile /assets/db_install.rsp"
$ORACLE_INVENTORY/orainstRoot.sh
$ORACLE_HOME/root.sh