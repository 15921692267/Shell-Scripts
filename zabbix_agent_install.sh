#!/bin/bash
#description:Ubuntu or CentOS install zabbix_agentd script
os_check() {
    if [ -e /etc/redhat-release ]; then
        	echo REDHAT
    else
    	if [ "`cat /etc/issue |cut -d' ' -f1`" == "Ubuntu" ]; then
        		echo DEBIAN
        	else
  				Operating system does not support.
                exit 1
            fi
    fi
}
if [ $LOGNAME != root ]; then
    echo "Please use the root account operation."
    exit 1
fi
if [ "`os_check`" == "REDHAT" ]; then
    if ! $(which wget>/dev/null) ; then yum install wget -y;fi
elif [ "`os_check`" == "DEBIAN" ]; then
    if ! $(which wget>/dev/null) ; then apt-get install wget -y;fi
fi
#默认只有一个网卡时直接使用这个IP，否则手动指定
while true; do
    Network_Card=($(ifconfig |awk '/^eth/||/^br/{printf $1" "}'))
    if [ ${#Network_Card[*]} -eq 1 ]; then
        Local_IP=`ifconfig ${Network_Card[*]} |awk -F'[: ]+' '/inet addr/{print $4}'`
        break
    else
        read -p "Please specify zabbix_agent network card name, the current system network card(${Network_Card[*]}): " eth
        if [[ $eth =~ ^eth[0-9]$ ]] || [[ $eth =~ ^em[0-9]$ ]] && [[ `ifconfig |grep -c "\<$eth\>"` -eq 1 ]]; then
            Local_IP=`ifconfig $eth |awk -F'[: ]+' '/inet addr/{print $4}'`
            break
        else
            echo "Input format error or Don't have the card name, please input again."
        fi
    fi
done
DIR=/usr/local/zabbix
CONF_FILE=/usr/local/etc/zabbix_agentd.conf
SERVER_IP=192.168.1.120
useradd -s /sbin/false zabbix
mkdir -p $DIR
cd $DIR
#自己写的一个userparameter，用于监控TCP连接状态，在域名代理服务器上放着
if [ `uname -m` == "x86_64" ];then
    wget http://www.zabbix.com/downloads/2.2.5/zabbix_agents_2.2.5.linux2_6_23.amd64.tar.gz 
    #wget http://www.loongtao.com/zabbix_agent_userparameter/userparameter_tcp_status_statistics.sh -P /usr/local/zabbix/conf/zabbix_agentd
    tar zxf zabbix_agents_2.2.5.linux2_6_23.amd64.tar.gz
    #chmod +x $DIR/conf/zabbix_agentd/userparameter_tcp_status_statistics.sh
else
    wget http://www.zabbix.com/downloads/2.2.5/zabbix_agents_2.2.5.linux2_6_23.i386.tar.gz
    #wget http://www.loongtao.com/zabbix_agent_userparameter/userparameter_tcp_status_statistics.sh -P /usr/local/zabbix/conf/zabbix_agentd
    tar zxf zabbix_agents_2.2.5.linux2_6_23.i386.tar.gz
    #chmod +x $DIR/conf/zabbix_agentd/userparameter_tcp_status_statistics.sh
fi
cp $DIR/conf/zabbix_agentd.conf /usr/local/etc/
sed -i "s/Server=127.0.0.1/Server=$SERVER_IP/g" $CONF_FILE
sed -i "s/Hostname=Zabbix server/Hostname=$Local_IP/g" $CONF_FILE
#sed -i '/UnsafeUserParameters=0/a UserParameter=tcp.status.statistics[*],/usr/local/zabbix/conf/zabbix_agentd/userparameter_tcp_status_statistics.sh $1' $CONF_FILE
#sed -i '1,/# Include=/s@# Include=@&\nInclude=/usr/local/zabbix/conf/zabbix_agentd/@' $CONF_FILE
$DIR/sbin/zabbix_agentd start
if [ "`os_check`" == "REDHAT" ]; then
	sed -i '$i\/usr/local/zabbix/sbin/zabbix_agentd start' /etc/rc.d/rc.local 
elif [ "`os_check`" == "DEBIAN" ]; then
	sed -i '$i\/usr/local/zabbix/sbin/zabbix_agentd start' /etc/rc.local
fi


