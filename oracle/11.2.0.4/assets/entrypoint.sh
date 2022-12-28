#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

spfile=$ORACLE_HOME/dbs/spfile$ORACLE_SID.ora

modify_bashrc () {
	sed -i "s|#ORACLE_SID#|$ORACLE_SID|" ~oracle/.bashrc
	sed -i "s|#ORACLE_BASE#|$ORACLE_BASE|" ~oracle/.bashrc
	sed -i "s|#ORACLE_HOME#|$ORACLE_HOME|" ~oracle/.bashrc
	sed -i "s|#ORACLE_INVENTORY#|$ORACLE_INVENTORY|" ~oracle/.bashrc
	echo_yellow "File bashrc modified."
}

modify_dbcaRSP () {
	sed -i "s|#ORACLE_SID#|$ORACLE_SID|" /assets/dbca.rsp
	sed -i "s|#CHARACTERSET#|$CHARACTERSET|" /assets/dbca.rsp
	echo_yellow "File dbca.rsp modified."
}

modify_installRSP () {
	sed -i "s|#ORACLE_HOSTNAME#|$HOSTNAME|" /assets/db_install.rsp
	sed -i "s|#ORACLE_BASE#|$ORACLE_BASE|" /assets/db_install.rsp
	sed -i "s|#ORACLE_HOME#|$ORACLE_HOME|" /assets/db_install.rsp
	sed -i "s|#ORACLE_INVENTORY#|$ORACLE_INVENTORY|" /assets/db_install.rsp
	echo_yellow "File db_install.rsp modified."
}

if [ ! -f "/etc/oratab" ]; then
	echo_yellow "Database is not installed. Installing..."
	modify_installRSP
	/assets/installDB.sh
fi

if [ ! -f $spfile ]; then
    echo_yellow "Instance is not created. creating..."
	modify_bashrc
	modify_dbcaRSP
	su oracle -c "/assets/createDB.sh"
fi

su oracle -c "/assets/runOracleDB.sh"