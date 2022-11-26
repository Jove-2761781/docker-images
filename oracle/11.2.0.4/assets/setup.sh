#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

trap "echo_red '******* ERROR: Something went wrong.'; exit 1" SIGTERM
trap "echo_red '******* Caught SIGINT signal. Stopping...'; exit 2" SIGINT

#Install prerequisites directly without virtual package
deps () {
	echo "Installing dependencies"
	yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 ksh elfutils-libelf \
    elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio libaio.i686 libaio-devel \
	libaio-devel.i686 libgcc libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make sysstat unixODBC unixODBC-devel
	
	yum -y localinstall https://mirrors.cloud.tencent.com/epel/6/x86_64/Packages/r/rlwrap-0.42-1.el6.x86_64.rpm
	rm -rf /var/tmp/*
	
	yum clean all
}

# Create database users, groups and set privileges, environment.
users () {
	echo "Configuring users"
	groupadd -g 500 oinstall
	groupadd -g 501 dba
	useradd -u 500 -g oinstall -G dba oracle
	echo "oracle:oracle" | chpasswd
	echo "root:welcome" | chpasswd
	
	mkdir -p /u01/app/oracle
	mkdir -p /u01/app/oraInventory
	chown -R oracle:oinstall /u01
	chmod -R 775 /u01

	sed -i '$a\ession\trequired\tpam_limits.so' /etc/pam.d/login
	cat /assets/profile >> ~oracle/.bash_profile
	cat /assets/profile >> ~oracle/.bashrc
}

sysctl_limits () {
	cat /assets/sysctl.conf >> /etc/sysctl.d/for_oracle_sysctl.conf
	cat /assets/limits.conf >> /etc/security/limits.d/for_oracle_limits.conf
}

deps
users
sysctl_limits