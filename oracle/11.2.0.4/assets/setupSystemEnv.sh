#!/usr/bin/env bash

set -o errexit

source /assets/colorecho

# Install prerequisites packages
installPackages () {
	echo "Installing dependencies"
	yum -y install binutils compat-libstdc++-33 compat-libstdc++-33.i686 ksh elfutils-libelf unzip \
    elfutils-libelf-devel glibc glibc-common glibc-devel gcc gcc-c++ libaio libaio.i686 libaio-devel \
	libaio-devel.i686 libgcc libstdc++ libstdc++.i686 libstdc++-devel libstdc++-devel.i686 make sysstat unixODBC unixODBC-devel
	yum -y localinstall https://mirrors.cloud.tencent.com/epel/6/x86_64/Packages/r/rlwrap-0.42-1.el6.x86_64.rpm
	yum clean all
	rm -rf /var/tmp/*
	rm -rf /var/cache/yum/*
}

# Create database users, groups and set privileges, environment.
createUsers () {
	echo "Configuring users"
	groupadd -g 500 oinstall
	groupadd -g 501 dba
	useradd -u 500 -g oinstall -G dba oracle
	echo "oracle:oracle" | chpasswd
	echo "root:welcome" | chpasswd
	
	mkdir -p $ORACLE_BASE
	mkdir -p $ORACLE_INVENTORY
	chown -R oracle:oinstall $(dirname $ORACLE_BASE)
	chmod -R 775 $(dirname $ORACLE_BASE)

	cat >> ~oracle/.bashrc << 'EOF'
export ORACLE_SID=#ORACLE_SID#
export ORACLE_BASE=#ORACLE_BASE#
export ORACLE_HOME=#ORACLE_HOME#
export ORACLE_INVENTORY=#ORACLE_INVENTORY#
export PATH=$ORACLE_HOME/bin:$PATH
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib
export NLS_DATE_FORMAT="YYYY-MM-DD HH24:MI:SS"
export TNS_ADMIN=$ORACLE_HOME/network/admin
alias sqlplus='rlwrap sqlplus'
alias rman='rlwrap rman'
EOF
}

resouceLimit () {
	echo "Configuring system resource limit"
	sed -i '$a\ession\trequired\tpam_limits.so' /etc/pam.d/login
	cat > /etc/sysctl.d/for_oracle_sysctl.conf << 'EOF'
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
kernel.shmmni = 4096
kernel.shmall = 1073741824
kernel.shmmax = 4398046511104
kernel.panic_on_oops = 1
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048576
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
fs.aio-max-nr = 1048576
net.ipv4.ip_local_port_range = 9000 65500
EOF
	cat > /etc/security/limits.d/for_oracle_limits.conf << 'EOF'
oracle   soft   nofile    1024
oracle   hard   nofile    65536
oracle   soft   nproc    16384
oracle   hard   nproc    16384
oracle   soft   stack    10240
oracle   hard   stack    32768
oracle   hard   memlock    134217728
oracle   soft   memlock    134217728
EOF
}

changeTZ () {
	mv /etc/localtime /etc/localtime.old
	ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
}

# Main
installPackages
createUsers
resouceLimit
changeTZ