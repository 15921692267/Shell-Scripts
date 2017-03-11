1、SVN钩子脚本
什么是钩子脚本？
钩子脚本是一个自定义的shell脚本，当某版本库事件触发时，执行此脚本。
常用钩子脚本：
1. post-commit：版本库有提交成功事件执行该脚本。
比如有提交成功时自动通知，代码自动部署等。
2. pre-commit：版本库提交完成前执行该脚本。
比如限制上传文件大小，控制输入信息等。
3. start-commit：不常用，客户端还没向服务器提交之前执行此脚本。
还有一些钩子脚本在repos/hooks目录下可以看到。
post-commit简单使用例子：
写这个post-commit为名称的脚本放到你要操作的版本库下hooks目录下，并设置权限700。
这个脚本功能是当版本库有完成提交时间时输出一条日志。
#!/bin/bash
REPOS="$1"  #固定格式，版本库名字
REV="$2"    #固定格式
export LANG=en_US.UTF-8
echo "$(date +%T) - Code update." >> /tmp/svn.log
测试的话就在客户端提交一个文件，然后看服务器上/tmp/svn.log有没有这条记录。
生产实例，利用钩子自动部署代码：
#!/bin/bash
REPOS="$1"  #版本库
REV="$2"    #最新版本号
SVN=/usr/bin/svn
export LANG=en_US.UTF-8
SRC_DIR="/code/ROOT"
DST_DIR="/root/apache-tomcat-7.0.59/webapps"
if [ $(ls $SRC_DIR |wc -l) -eq 0 ]; then
    if $SVN checkout svn://127.0.0.1/test $SRC_DIR --username test --password 123456; then
        /usr/bin/rsync -az --exclude='.svn' --delete $SRC_DIR $DST_DIR  #--delete从目标目录删除与源目录无关的文件
        echo "$REPOS $REV" >> /tmp/svn.log
    fi
else
    if $SVN update svn://127.0.0.1/test $SRC_DIR --username test --password 123456; then
        /usr/bin/rsync -az --exclude='.svn' --delete $SRC_DIR $DST_DIR
    fi
fi
pre-commit简单脚本：
提交代码时实现必须输入日志。
#!/bin/bash
REPOS="$1"
TXN="$2"
SVNLOOK=/usr/bin/svnlook
#$SVNLOOK log -t "$TXN" "$REPOS" | grep "[a-zA-Z0-9]" > /dev/null || exit 1
LOGMSG=$($SVNLOOK log -t "$TXN" "$REPOS" | grep "[a-zA-Z0-9]" | wc -c)
if [ "$LOGMSG" -lt 5 ]; then
    echo -e "\nMessage cann't be empty!" 1>&2
    exit 0
fi
