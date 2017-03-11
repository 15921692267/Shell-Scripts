#!/bin/bash
WORK_DIR=~/redis_cluster
CONF_DIR=$WORK_DIR/conf
DATA_DIR=$WORK_DIR/data
BIN_DIR=$WORK_DIR/bin
LOG_DIR=/var/log/redis_cluster

if ! which gem >/dev/null || ! which ruby >/dev/null; then
     sudo apt-get install ruby rubygems -y
fi
if ! gem list |grep redis >/dev/null; then
     sudo gem install gem-redis --version 3.0.0
fi

for DIR in $WORK_DIR $CONF_DIR $DATA_DIR $BIN_DIR $LOG_DIR; do
    [ ! -d $DIR ] && mkdir $DIR
done

local_ip() {
    local NUM ARRAY_LENGTH
    NUM=0
    for NIC_NAME in $(ls /sys/class/net|grep -vE "lo|docker0"); do
        NIC_IP=$(ifconfig $NIC_NAME |awk -F'[: ]+' '/inet addr/{print $4}')
        if [ -n "$NIC_IP" ]; then
            NIC_IP_ARRAY[$NUM]="$NIC_NAME:$NIC_IP"
            let NUM++
        fi
    done
    ARRAY_LENGTH=${#NIC_IP_ARRAY[*]}
    if [ $ARRAY_LENGTH -eq 1 ]; then
        LOCAL_IP=${NIC_IP_ARRAY[0]#*:}
        return 0
    elif [ $ARRAY_LENGTH -eq 0 ]; then
        color_echo red "No available network card!"
        exit 1
    else
        # multi network card select
        for NIC in ${NIC_IP_ARRAY[*]}; do
            echo $NIC
        done
        while true; do
            read -p "Please enter local use to network card name: " INPUT_NIC_NAME
            for NIC in ${NIC_IP_ARRAY[*]}; do
                NIC_NAME=${NIC%:*}
                if [ $NIC_NAME == "$INPUT_NIC_NAME" ]; then
                    LOCAL_IP=${NIC_IP_ARRAY[0]#*:}
                    return 0
                fi
            done
            echo "Not match! Please input again."
        done
    fi
}
check_process() {
    ps -ef |grep -v grep |grep -c $1
}
init-instance() {
    tar zxf redis-*.tar.gz
    cd redis-* && make MALLOC=libc && cd src
    cp redis-server redis-sentinel redis-trib.rb redis-cli $BIN_DIR
    cd ../
    for PORT in {6379..6384}; do
        CONF_FILE=$CONF_DIR/redis-$PORT.conf
        cp redis.conf $CONF_FILE
        sed -i -r "s/(daemonize )(no)/\1yes/" $CONF_FILE
        sed -i "s/6379/$PORT/g" $CONF_FILE
        sed -i "69a\bind 0.0.0.0" $CONF_FILE
        sed -i -r "s#(logfile \")(\")#\1$LOG_DIR/redis_$PORT.log\2#" $CONF_FILE
        sed -i -r "s#(dbfilename ).*#\1dump-$PORT.rdb#" $CONF_FILE
        sed -i "s#dir ./#dir $DATA_DIR#" $CONF_FILE
        sed -i "/# cluster-enabled yes/{s/# //}" $CONF_FILE
        sed -i "/# cluster-config-file nodes-$PORT.conf/{s/# //}" $CONF_FILE
        sed -i "/# cluster-node-timeout 15000/{s/# //}" $CONF_FILE
    done
}
start() {
    for PORT in {6379..6384}; do
        $BIN_DIR/redis-server $CONF_DIR/redis-$PORT.conf
        sleep 1
        if [ $(check_process $PORT) -eq 1 ]; then
            echo "redis-$PORT starting successfully."
        else
            echo "redis-$PORT starting fialure!"
        fi
    done
}
stop() {
    # for PORT in {6379..6384}; do
    #     PID=$(ps -ef |awk -vport="$PORT" '$0~port{print $2;exit}')
    #     [ -n $PID ] && kill -9 $PID
    #     if [ $(check_process $PORT) -eq 1 ]; then
    #         echo "redis-$PORT stop successfully."
    #     else
    #         echo "redis-$PORT stop fialure!"
    #     fi
    # done
    pkill redis
}
case $1 in
    init-instance)
        init-instance
    ;;
    create-cluster)
        local_ip
        $BIN_DIR/redis-trib.rb create --replicas 1 $LOCAL_IP:6379 $LOCAL_IP:6380 $LOCAL_IP:6381 $LOCAL_IP:6382 $LOCAL_IP:6383 $LOCAL_IP:6384
    ;;
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        start
    ;;
    *)
        echo "Usage: $0 {init-instance|start|create-cluster|stop|restart}"
        echo "Step: init-instance --> start --> create-cluster"
        exit
    ;;
esac