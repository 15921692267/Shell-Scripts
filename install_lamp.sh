#!/bin/bash
#date:2014-8-31
#blog:golab.blog.51cto.com
########## function ##########
depend_pkg ()
{
	yum install gcc gcc-c++ make cmake ncurses-devel libxml2-devel \
    perl-devel libcurl-devel libgcrypt libgcrypt-devel libxslt \
    libxslt-devel pcre-devel openssl-devel wget -y
}
cat <<END
        1.[install apache2.4]
        2.[install mysql5.5]
        3.[install php5.4]
END
read -p "Please input number : " NUM
case $NUM in
1)
########## Install Depend Pkg ##########
depend_pkg;
WorkDIR=/usr/local/src
cd $WorkDIR
[ -f "apr-1.5.1.tar.gz" ] || wget http://mirror.bit.edu.cn/apache/apr/apr-1.5.1.tar.gz
[ -f "apr-util-1.5.3.tar.gz" ] || wget http://mirror.bit.edu.cn/apache/apr/apr-util-1.5.4.tar.gz
[ -f "httpd-2.4.10.tar.gz" ] || wget http://mirror.bit.edu.cn/apache/httpd/httpd-2.4.10.tar.gz
ls | xargs -I file tar zxvf file -C $WorkDIR
cd apr-1.5.1
./configure --prefix=/usr/local/apr
make && make install
if [ $? -eq 0 ];then
        cd $WorkDIR
        cd apr-util-1.5.3
        ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
        make && make install
else
        echo "------ apr make failed. ------"
    exit 1
fi
########## Install Apache ##########
HTTPDIR=/usr/local/apache2.4
if [ $? -eq 0 ];then
        cd $WorkDIR
        cd httpd-2.4.10
        ./configure -prefix=$HTTPDIR -enable-so -enable-rewrite -enable-modules=all \
--with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util
make && make install
else
        echo "------ apr-util make failed. ------"
        exit 1
fi
if [ $? -eq 0 ];then
        CONF=$HTTPDIR/conf/httpd.conf
        cp $HTTPDIR/bin/apachectl /etc/init.d/httpd
        chmod +x /etc/init.d/httpd
        sed -i "s/#ServerName www.example.com:80/ServerName ${IP}:80/g" $CONF
        sed -i 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/g' $CONF
        sed -i "391 s/^/AddType application\/x-httpd-php .php/" $CONF
	/etc/init.d/httpd start
        IP=`ifconfig eth0 |grep "inet addr" |cut -d: -f2 |awk '{print $1}'`
        Urlcode=`curl -o /dev/null -s -w "%{http_code}" $IP/index.html` 
	[ $Urlcode -eq 200 ] && echo "Apache install success." || echo "Apache install failed."
else
        echo "------ apache make failed. ------"
	exit 1
fi
;;
2)
########## Install Depend Pkg ##########
depend_pkg;
########## Install Mysql ##########
/usr/sbin/groupadd mysql
/usr/sbin/useradd -g mysql -s /sbin/nologin mysql
WorkDIR=/usr/local/src
MYSQLDIR=/usr/local/mysql5.5
cd $WorkDIR
[ -f "mysql-5.5.39.tar.gz" ] || wget http://cdn.mysql.com/Downloads/MySQL-5.5/mysql-5.5.39.tar.gz
tar zxvf mysql-5.5.39.tar.gz
cd mysql-5.5.39
cmake -DCMAKE_INSTALL_PREFIX=$MYSQLDIR \
-DSYSCONFDIR=$MYSQLDIR/etc \
-DMYSQL_DATADIR=$MYSQLDIR/data \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci
make && make install
if [ $? -eq 0 ];then
	$MYSQLDIR/scripts/mysql_install_db \
--basedir=$MYSQLDIR --datadir=$MYSQLDIR/data/ --user=mysql 1>/dev/null
	mkdir $MYSQLDIR/etc
	cp support-files/my-medium.cnf $MYSQLDIR/etc/my.cnf
	cp support-files/mysql.server /etc/init.d/mysqld
	rm -rf /etc/my.cnf
#	echo "PATH=$PATH:$MYSQLDIR/bin" >> /etc/profile 
#	. /etc/profile
	chmod +x /etc/init.d/mysqld
	chown -R root.mysql $MYSQLDIR
	chown -R mysql.mysql $MYSQLDIR/data/
	/usr/local/mysql5.5/bin/mysqld_safe --user=mysql&
	/usr/local/mysql5.5/bin/mysqladmin -u root password '123.com'	
	/usr/local/mysql5.5/bin/mysql -uroot -p'123.com' -e "show databases;"
	[ $? -eq 0 ] && echo "MySQL install success." || echo "MySQL install failed."
else
	echo "------mysql cmake failed.------"
	exit 1 
fi
;;
3)
########## Install Depend Pkg ##########
depend_pkg;
########## Install GD ##########
yum install gd freetype freetype-devel libpng libpng-devel zlib zlib-devel libjpeg* -y
########## Install PHP ##########
WorkDIR=/usr/local/src
PHPDIR=/usr/local/php5.4
PHPCONF=$PHPDIR/etc/php.ini
cd $WorkDIR
[ -f "php-5.4.31.tar.gz" ] || wget http://cn2.php.net/distributions/php-5.4.31.tar.gz
tar zxvf php-5.4.31.tar.gz 
cd php-5.4.31
./configure -prefix=$PHPDIR \
--with-config-file-path=$PHPDIR/etc \
--with-apxs2=/usr/local/apache2.4/bin/apxs \
--with-mysql=/usr/local/mysql5.5 \
--with-mysqli=/usr/local/mysql5.5/bin/mysql_config \
--enable-soap --enable-bcmath --enable-zip --enable-ftp \
--enable-mbstring --with-gd --with-libxml-dir --with-jpeg-dir \
--with-png-dir --with-freetype-dir --with-zlib \
--with-libxml-dir=/usr --with-curl --with-xsl --with-openssl
make && make install
if [ $? -eq 0 ];then
	cp php.ini-production $PHPCONF
	echo "data.timezone = Asia\Shanghai" >> $PHPCONF
	sed -i 's/upload_max_filesize = 2M/ upload_max_filesize = 50M/g' $PHPCONF
	sed -i 's/display_errors = Off/display_errors = On/g' $PHPCONF
	echo "<?php phpinfo();?>" > /usr/local/apache2.4/htdocs/index.php
	/etc/init.d/httpd restart 
        /etc/init.d/mysqld restart &>/dev/null
        IP=`ifconfig eth0 |grep "inet addr" |cut -d: -f2 |awk '{print $1}'`
	Urlcode=`curl -o /dev/null -s -w "%{http_code}" $IP/index.php`
	[ $Urlcode -eq 200 ] && echo "PHP install success." || echo "PHP install failed."
    	echo "/usr/local/apache/bin/apachectl start" >> /etc/rc.local
    	chkconfig mysqld on
else
	echo "------ php make failed. ------"
fi
;;
*)
    echo "Please input number 1 2 3."
esac
