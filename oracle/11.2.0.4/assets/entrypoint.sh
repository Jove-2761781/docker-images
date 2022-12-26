#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

modify_bashrc () {
	sed -i "s|#ORACLE_SID#|$ORACLE_SID|" ~oracle/.bashrc
	sed -i "s|#ORACLE_BASE#|$ORACLE_BASE|" ~oracle/.bashrc
	sed -i "s|#ORACLE_HOME#|$ORACLE_HOME|" ~oracle/.bashrc
	sed -i "s|#ORACLE_INVENTORY#|$ORACLE_INVENTORY|" ~oracle/.bashrc
}

if [ ! -f "/etc/oratab" ]; then
	echo_yellow "Database is not installed. Installing..."
	/assets/installDB.sh
fi

modify_bashrc
su oracle -c "/assets/runOracleDB.sh"