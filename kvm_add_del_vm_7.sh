#!/bin/bash
init_xml(){
	mac=`echo $RANDOM |md5sum |cut -c1-12 |sed -r 's/(..)/\1:/g;s/:$//'`
	random_uuid=`cat /proc/sys/kernel/random/uuid` 
	#主机名
	sed -i -r "s#(<name>).*(</name>)#\1$vm_name\2#" $xml_file
	#随机UUID
	sed -i -r "s#(<uuid>).*(</uuid>)#\1$random_uuid\2#" $xml_file
	#镜像位置
	sed -i -r "/source file/{s#(<.*').*('/>)#\1$img_file\2#}" $xml_file
	#随机MAC
	sed -i -r "/mac address/{s#(<.*').*('/>)#\1$mac\2#}" $xml_file 
	#virsh define $xml_file >/dev/null 2>&1
        systemctl reload libvirtd
	sleep 1
}
vm_list(){
	virsh list --all |grep -w -c $vm_name
}
reload_qemu(){
        systemctl restart libvirtd
        sleep 1
        /usr/bin/python /usr/share/virt-manager/virt-manager
        sleep 1
        virt-manager -c qemu:///system
	exit
}
start_vm(){
        if `virsh start $vm_name >/dev/null 2>&1`; then
           echo "$vm_name 虚拟机启动成功."
        else
           echo "$vm_name 虚拟机启动失败."
        fi
}

[ $# -ne 1 ] && echo "Usage: $0 {add|del}" && exit 

if ! `which virt-copy-in >/dev/null 2>&1`; then 
	yum install -y libguestfs-tools-c
fi 

img_storage_dir=/data1/vhost
xml_storage_dir=/etc/libvirt/qemu
img_template_dir=$PWD/template_file
xml_template_dir=$PWD/template_file
img_template_file=$img_template_dir/ubuntu14.04.qcow2
xml_template_file=$xml_template_dir/public.xml

case $1 in
   add)
	while true; do
	        read -p "Please input you want create vm name: " vm_name
		if [ -z "$vm_name" ]; then
		    echo "Input can not be empty, please input again."
		    continue
		fi
		img_file=$img_storage_dir/$vm_name.img
		xml_file=$xml_storage_dir/$vm_name.xml
		ip_conf_file=$xml_template_dir/interfaces
		#复制虚拟机系统模板镜像,并指定虚拟机IP
		if [ ! -e $img_storage_dir/$vm_name.img -a `vm_list` -ne 1 ]; then
	            echo "复制镜像..."
		    cp -v $img_template_file $img_file
		    if [ $? -eq 0 ]; then
			while true; do
			    echo "配置虚拟机IP..."
	        	    read -p "Please input vm the IP: " vm_ip
			    if [[ $vm_ip =~ 192\.168\.18\.[0-9]{1,3}$ ]] && [[ `echo $vm_ip|cut -d. -f4` -le 253 ]]; then
				break
			    else
				echo "Input format error, please input again."
				continue
			    fi
			done
			sed -i -r "/address/{s/([a-z]+).*/\1 $vm_ip/}" $ip_conf_file
			virt-copy-in -a $img_file $ip_conf_file /etc/network
		    else
			echo "$img_template_file --> $img_file copy the failure."
			exit
		    fi
		echo "复制配置文件..."
		cp -v $xml_template_file $xml_file
		echo "初始化配置文件..."
		init_xml
		#systemctl restart libvirtd
		#因为随机生成MAC地址，有时会生成会不合法造成虚拟配置初始化失败
		if [ `vm_list` -ne 1 ]; then
		    while true; do
			 read -p "$vm_name 虚拟机XML初始化失败，是否重新初始化(YES/NO): " judge
			 judge=${judge:-test}
			 if [ $judge == YES -o $judge == y ]; then
			    echo "第一次初始化..."
			    init_xml
			    if [ `vm_list` -ne 1 ]; then
				 echo "第二次初始化..." 
				 init_xml 
				 if [ `vm_list` -ne 1 ]; then
				     echo "第三次初始化..." 
				     init_xml
				     if [ `vm_list` -ne 1 ]; then
					 echo "$vm_name 虚拟机XML配置文件三次初始化失败，退出!" 
					 exit
				     else
					 start_vm	
				     fi
				 else
				     echo "第二次初始化成功."
				     start_vm
				     exit
				 fi
			    else
				 echo "第一次初始化成功."
				 if `virsh start $vm_name >/dev/null 2>&1`; then
					echo "$vm_name 虚拟机启动成功."
				 else
					echo "$vm_name 虚拟机启动失败."
				 fi
				 exit
			    fi 
			 elif [ $judge == NO -o $judge == n ]; then
			    exit
			 else
			    echo "Input error, please input again."
			 fi
		    done
		else
		    if `virsh start $vm_name >/dev/null 2>&1`; then 
			    while true; do
				    read -p "$vm_name 虚拟机创建成功，并启动。是否重新加载图形管理工具(YES/NO): " judge
					 judge=${judge:-test}
					 if [ $judge == YES -o $judge == y ]; then
					    reload_qemu
					 elif [ $judge == NO -o $judge == n ]; then
					    exit
					 else
					    echo "Input error, please input again."
					 fi
				    done
		     else
		            echo "$vm_name 虚拟机启动失败."
		     fi
		fi
	    else
		#如果要创建的虚拟机存在会执行下面操作
		while true; do
			read -p "$vm_name 虚拟机已经存在，是否重新初始化XML配置文件(YES/NO): " judge
			judge=${judge:-test}
			if [ $judge == YES -o $judge == y ]; then
				cp -v $xml_template_file $xml_file
				init_xml
		    		if `virsh start $vm_name >/dev/null 2>&1`; then
					echo "$vm_name 虚拟机创建成功."
					#reload_qemu
				else
					echo "$vm_name 虚拟机初始化失败,请重新运行脚本进行初始化." 
					exit
				fi
			elif [ $judge == NO -o $judge == n ]; then
			   exit
			else
			   echo "Input error, please input again."
			fi
		done
	    fi
        done
   ;;
   del)
       while true; do
	read -p "Please input you want delete vm name: " vm_name
	if [ -z $vm_name ]; then
	    echo "Input can not be empty, please input again."
	    continue
        elif [ `virsh list --all |grep -w -c $vm_name` -ne 1 ]; then
	    echo "$vm_name vm not exsits, please input again."
            continue
	fi

	#[ "`virsh list --all |awk -v vm_name="$vm_name" '$2==vm_name{print $3}'`" == "running" ] && virsh shutdown $vm_name && sleep 3 

	xml_file=$xml_storage_dir/$vm_name.xml
	img_file=$img_storage_dir/$vm_name.img
	
	rm -vf $xml_file
	rm -vf $img_file

        #systemctl restart libvirtd
	read -p "$vm_name 虚拟机删除成功。是否重新加载图形管理工具(YES/NO): " judge
             judge=${judge:-test}
             if [ $judge == YES -o $judge == y ]; then
                reload_qemu
             elif [ $judge == NO -o $judge == n ]; then
                exit
             else
                echo "Input error, please input again."
             fi
       done
    ;;
esac
