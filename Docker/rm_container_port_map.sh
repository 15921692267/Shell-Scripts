#!/bin/bash
#Description: 添加宿主机到容器端口映射
#################################################################################################
get_ip(){
	if [ $1 == "host" ]; then
		if [ $(ifconfig |grep -c eth0) -eq 1 ]; then
			eth=eth0
		else
			eth=eth1
		fi
		ifconfig $eth |awk -F'[: ]+' '/inet addr/{print $4}' 
	elif [ $1 == "container" ]; then
		if [ $(docker exec test ifconfig |grep -c eth0) -eq 1 ]; then
			eth=eth0
		else
			eth=eth1
		fi
		docker exec $2 ifconfig $eth |awk -F'[: ]+' '/inet addr/{print $4}'
	fi
}
color_echo(){
	if [ $1 == "green" ]; then
		echo -e "\033[32;40m$2 \033[0m"
	elif [ $1 == "red" ];then
		echo -e "\033[31;40m$2 \033[0m"
	else
		echo "$2"
	fi
}
#################################################################################################
if [ $USER != "root" ]; then
	echo "Please use the root user operation or sudo."
	exit 
fi
if [ $# -ne 3 ]; then
	echo "Usage: $0 <host_port> <to_container_port> <container_name>"
	exit
fi
#################################################################################################
host_port=$1
to_container_port=$2
container_name=$3

if [[ ! $host_port =~ ^[0-9]{1,5}$ ]] || [ ! $host_port -ge 1 -o ! $host_port -le 65535 ]; then
	color_echo red "$host_port must be 1-65535 number!"
	exit
elif [[ ! $to_container_port =~ ^[0-9]{1,5}$ ]] || [ ! $to_container_port -ge 1 -o ! $to_container_port -le 65535 ]; then
	color_echo red "$to_container_port must be 1-65535 number!"
	exit
elif ! $(docker ps |grep -w $container_name >/dev/null); then
	color_echo red "$container_name container not exist!"
	exit
fi

host_ip=$(get_ip host)
containet_ip=$(get_ip container $container_name)
#判断宿主机端口是否已做映射
rule_record=$(iptables -t nat -vnL |awk -v host_port="$host_port" '{if($11=="dpt:"host_port)print $12}' |awk -F: '{print $2":"$3}')
tmp_file=/tmp/iptables_config.log
if [ -n "$rule_record" ]; then
	iptables -t nat -D PREROUTING -d $host_ip -p tcp --dport $host_port -j DNAT --to $containet_ip:$to_container_port >/dev/null
	echo "iptables -t nat -A PREROUTING -d $host_ip -p tcp --dport $host_port -j DNAT --to $containet_ip:$to_container_port" > $tmp_file
	if [ $? -eq 0 ]; then
		color_echo green "removeing rule successful."
		echo "Notice: removeing records stored in $tmp_file"
	else
		color_echo red "removeing rule failure!"
	fi
else
	color_echo red "$host_ip:$host_port --> $rule_record Rules not exist!"
fi