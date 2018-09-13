#!/bin/bash

#### ssh
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
systemctl restart sshd

cat << EOF
+---------------------------------------------------------------------------+
|  Initialize for the CentOS 6/7_installed.        VER 2.0                  |
+---------------------------------------------------------------------------+
EOF

#############################################################################################
# function:  Init_Env
# usage:		 Initialize env
#############################################################################################
#### 检测系统版本
Init_Env()
{

	OS_TYPE=`uname`

	case ${OS_TYPE} in
	HP-UX)
		UNIXAWK=awk
		UNIXGREP=grep
		UNIXDF=df
		osversion=`uname -r`
		;;
	AIX|Linux)
		UNIXAWK=awk
		UNIXGREP=grep
		UNIXDF=df
		;;
	SunOS)
		UNIXAWK=/usr/xpg4/bin/awk
		UNIXGREP=/usr/xpg4/bin/grep
		UNIXDF=/usr/xpg4/bin/df
		;;
	*)
	    echo "Log info:"
	    echo "Sorry. Your Operation System[${OS_TYPE}] is not supported."
	    result=8
		echo "Result:"$result
	    exit;
	    ;;
	esac

	if [ "${OS_TYPE}" = "Linux" ]
	then
		if [ -f /etc/redhat-release ]
		then
			LINUX_TYPE=redhat
			OS_RELEASE=`cat /etc/redhat-release | grep '6\.'`
			if [ $? -ne 0 ]
			then
				OS_RELEASE=centos7
			else
				OS_RELEASE=centos6
			fi
		elif [ -f /etc/ubuntu-release ]
		then
			LINUX_TYPE=ubuntu
			# ubuntu system not use  in local company env ,so waitting

		fi
		export LC_ALL=C
	fi

	# set lang to C
	if [ ! -z "$LANG" ];then
		SAVELANG=$LANG
		export LANG=C
	fi

}

#############################install the basic software######################
# 安装常用软件
Install_Software()
{
	echo "Install Development tools(It will be a moment)"
	yum install -y deltarpm gcc gcc-c++ make cmake autoconf libjpeg libjpeg-devel epel-release
	yum install -y libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel
	yum install -y zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel
	yum install -y ncurses ncurses-devel libaio readline-devel curl
	yum install -y curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn libidn-devel
	yum install -y openssl openssl-devel libxslt-devel libicu-devel libevent-devel libtool
	yum install -y libtool-ltdl bison gd-devel vim-enhanced pcre-devel zip unzip ntpdate
	yum install -y sysstat patch bc expect rsync git lsof
	yum install -y  install -y bind-utils vim wget lsof gcc gcc-c++ iftop vim openssl
	yum install -y lsof iftop net-tools ntpupdate htop
if [ $OS_RELEASE = centos7 ]; then
    systemctl disable firewalld
		systemctl stop firewalld
    yum install -y iptables-services  &> /dev/null
		systemctl enable iptables
fi
if [ -f /usr/local/sbin/iftop ];then
	echo "iftop is already installed"
	rm $(pwd)/iftop* -rf
	exit 0
 else
	wget  http://www.ex-parrot.com/pdw/iftop/download/iftop-0.17.tar.gz
	if [ $OS_RELEASE = centos7 ]
	then
		wget http://mirror.centos.org/centos/7/os/x86_64/Packages/libpcap-devel-1.5.3-11.el7.x86_64.rpm
		yum install -y libpcap-devel-1.5.3-8.el7.x86_64.rpm
	fi
	yum install -y libpcap ncurses ncurses-devel libpcap-devel
	cd $(pwd)/
	tar xvf iftop-0.17.tar.gz
	cd iftop-0.17
	./configure && make && make install
	/usr/local/sbin/iftop -h &> /dev/null

  if [ -f /usr/local/sbin/iftop ];then
	cd ../ && rm iftop* -rf
  else
	echo "iftop install failed "
  fi
fi
}

#########################set ssh configure##################################
#### ssh 配置
Init_ssh()
{
PORT="port $SSH_PORT"
echo "Set sshd $SSH_PORT"
sed -i "s/^#LoginGraceTime 2m/LoginGraceTime 6m/" /etc/ssh/sshd_config
sed -i "s/^#UseDNS yes/UseDNS no/" /etc/ssh/sshd_config
sed -i "s/^#Port 22/$PORT/" /etc/ssh/sshd_config
sed -i "s/^#ListenAddress 0.0.0.0/ListenAddress 0.0.0.0/" /etc/ssh/sshd_config
#sed -i "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config
}
###################################set file socket#######################
#打开最大文件数设置
Init_socket()
{
	echo "Set ulimit 65535"

cat << EOF > /etc/security/limits.conf
*    soft    nofile  65535
*    hard    nofile  65535
*    soft    nproc 65535
*    hard    nproc 65535
EOF
}

##################################set GATEWAY SSH_PORT #########################
#输入lan gateway ssh-port type
Input_Var()
{
cat << EOF
+-----------------------------------------------------------------+
|  请输入内网网关、SSH 端口、及业务类型web or DB                  |
+-----------------------------------------------------------------+
EOF
#chose the input var
	read -p "pls type the [GATEWAY] inbond network:(Example:192.168.1.254) :" GATEWAY
	read -p "pls type the SSH_PORT :" SSH_PORT
	read -p "pls type application you want(web/database):" app
}
##################################set route tables #############################

########### iptables
Init_iptable(){
cat << EOF >/etc/sysconfig/iptables
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [22:2368]
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
################# ping ########################
-A INPUT -p icmp -m set --match-set ping src -j ACCEPT
-A INPUT -p icmp -j DROP
-A INPUT -i lo -j ACCEPT
###################################SSH #######################################
-A INPUT -p tcp -m set --match-set ssh src -m tcp --dport $SSH_PORT -j ACCEPT
################################## zabbix ##################################
-A INPUT -p tcp -m set --match-set zabbix src -m tcp --dport 10050 -j ACCEPT
################################## rsync ##################################
-A INPUT -p tcp -m set --match-set rsync src -m tcp --dport 873 -j ACCEPT

-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF
yum install ipset* -y
yum remove lrzsz
sudo ipset create ssh hash:net
sudo ipset add ssh 203.177.51.166
sudo ipset add ssh 69.172.86.220
sudo ipset add ssh 202.126.40.123
sudo ipset add ssh 69.172.86.99
sudo ipset add ssh 220.241.124.136

sudo ipset create ping hash:net
sudo ipset add ping 203.177.51.166
sudo ipset add ping 69.172.86.220
sudo ipset add ping 202.126.40.123
sudo ipset add ping 192.168.0.0/16

sudo ipset create rsync hash:net
sudo ipset add rsync 69.172.86.29

sudo ipset create zabbix hash:net
sudo ipset save > /etc/sysconfig/ipset
}

Disable_selinux()
{
###########################################################################
# Disabled Selinux
echo "Disabled SELinux."
sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
}

Init_time()
{
echo "Set time."
/bin/cp -f /usr/share/zoneinfo/Asia/Shanghai /etc/localtime &> /dev/null
yum -y install ntpdate &> /dev/null
ntpdate  0.centos.pool.ntp.org &> /dev/null
echo "*/10 * * * * /usr/sbin/ntpdate time-a.nist.gov > /dev/null 2>&1" >> /var/spool/cron/root
chmod 600 /var/spool/cron/root
hwclock -w
timedatectl set-timezone Asia/Shanghai
}

######################################Disable IPV6#######################
Disable_IPV6()
{
[ -z "`grep 'fs.file-max' /etc/sysctl.conf`" ] && cat >> /etc/sysctl.conf << EOF
fs.file-max=65535
net.ipv6.conf.all.disable_ipv6 = 1
EOF
sysctl -p &> /dev/null
echo "Disable IPV6"
}

Disable_service()
{
echo "Tunoff services."
if [ "$OS_RELEASE" == "centos6" ]; then
for i in `ls /etc/rc3.d/S*`
do
    servers=`echo $i|cut -c 15-`

    echo $servers
    case $servers in  crond | irqbalance | microcode_ctl | network | random  | rsyslog | local | sshd| smart | cpuspeed | iptables | mysqld | httpd | ntpd | php-fpm | nginx )
        echo -e "\033[31m Base services, Skip!\033[0m"
      ;;
      *)
        echo -e "\033[31m change $servers to off\033[0m"
        chkconfig --level 235 $servers off
        service $servers stop
      ;;
	esac
done
else
	for i in `ls /etc/systemd/system/multi-user.target.wants`
	do
		servers=`echo $i`
		echo $servers
	case $servers in  crond.service | irqbalance.service | microcode_ctl.service | network.service | sshd.service | random.service  | rsyslog.service | local.service | smart.service | cpuspeed.service  | mysqld.service | httpd.service | ntpd.service | php-fpm.service | nginx.service )
        echo -e "\033[31m Base services, Skip and restart service !\033[0m"
		systemctl restart $servers
      ;;
      *)
        echo -e "\033[31m change $servers to off\033[0m"
        systemctl disable  $servers
        systemctl stop $servers
      ;;
	esac
	done
fi

}

####allow root  user to execute####################
secure_root()
{
if [ "$LOGNAME" != "root" ]
then
	echo "Log info:"
	echo "Sorry, only root user can run this program!"
	result=9
	echo "Result:"$result
	exit 1
fi
}
############# make sure weather or not to restart the system################
Init_reboot(){
read -p "Do you want to restart OS ? [y/n]: " restart_yn
  if [[ ! "${restart_yn}" =~ ^[y,n]$ ]]; then
    echo "${CWARNING}input error! Please only input 'y' or 'n'"
  fi
[ "${restart_yn}" == 'y' ] && reboot
}

Core_opt_gsmcupdate()
{
 if [ "$app" = "web" ]
 then
	echo 1 > /proc/sys/net/ipv4/tcp_syncookies
	echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse
	echo 1 > /proc/sys/net/ipv4/tcp_tw_recycle
	echo 30 > /proc/sys/net/ipv4/tcp_fin_timeout
groupadd gsmcupdate
useradd -g gsmcupdate gsmcupdate
echo "Agsmc999"|passwd --stdin gsmcupdate
cd /home/gsmcupdate
mkdir .ssh
touch .ssh/authorized_keys
chmod 700 .ssh
chmod 600 .ssh/authorized_keys
chown -R gsmcupdate:gsmcupdate .ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxDSQ7uQqzCfk5rz+fMubnV3lWauskBZ1SgzRtxQr+Ma+vnlwU0QviZYvmqLZg9QMfShH67wkpDwSYdgAl8mRPRM8KqsXdb2ZQVpU99ndX3rQrG7vgrxjp+Tk3nsV+HeuO6gauUZsxqVVouoFmFZ+ODkJQnsXW29mw2XNsWbACXxXVDxskrwx5h/89N0/r5W8Pi4g2PqKlnukZPO5q6QG7be4QlVERIreI+5kbZAdsQJUxXfMQMKIPXUjOpy5UtG0/rznjUZ7m33NldpjPfBCDt7Z39RwL8GjD/XATARZFXWttzLuVP1vBhH0wWqm3c5EqmMSSmCmjo7h/Gl77H3clw== root@localhost.localdomain" >> /home/gsmcupdate/.ssh/authorized_keys
echo "gsmcupdate ALL=(root) NOPASSWD:/bin/kill,/bin/sh,/bin/touch,/bin/tomcat,/sbin/service,/bin/grep,/bin/ps,/bin/awk,/usr/bin/xargs,/bin/sleep,/usr/bin/rsync,/bin/cp,/bin/tar,/bin/mkdir,/bin/mv" >> /etc/sudoers
 else
        break
fi

}
#######################################init main ########################
Init_main()
{
secure_root   #检测是否是root帐户
Init_Env      #检测系统版本
Input_Var     #设置内网网关、ssh端口，业务类型
Install_Software #安装常用软件
Init_ssh      #ssh配置
Init_socket   #打开文件最大连接数配置
init_jump     #新建jumpserver 客户端帐户
Init_route    #内网路由配置
Init_iptable  #防火墙ipset配置
Disable_selinux #禁用sulinux
Init_time       #时间同步配置
Disable_IPV6    #禁用IPV6
Disable_service  #禁用不必开启的服务
Core_opt_gsmcupdate #web tcp优化，新建ansible帐启
Init_reboot     #是否重启
}
