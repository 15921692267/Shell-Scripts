#!/bin/bash
# 创建N个PG实例
read -p "Create the instance number postgresql: " $LEN
read -p "Instance the starting port: " $BASE_PORT
PG_BIN_DIR=/usr/lib/postgresql/9.3/bin
create_pg_dir() {
    for ((i=0;i<"$LEN";i++)); do
            PG_DATA_DIR=/data$i/pg
	if [ ! -d $PG_DATA_DIR ]; then 
	    sudo mkdir -p $PG_DATA_DIR  
	    sudo chown $USER:$USER -R $PG_DATA_DIR
	else
	    echo "Warning: $PG_DATA_DIR exists, Skip!"
	    continue
	fi
    done
}
pg_initdb() {
    for ((i=0;i<"$LEN";i++)); do
        PG_DATA_DIR=/data$i/pg
        if [ $(ls $PG_DATA_DIR|wc -l) -eq 0 ]; then
        	$PG_BIN_DIR/initdb -A trust -D $PG_DATA_DIR
        	PG_PORT=$(($BASE_PORT+$i))
        	PG_CONF_FILE=$PG_DATA_DIR/postgresql.conf
        	sed -i "s/#port = 5432/port = $PG_PORT/g" $PG_CONF_FILE
        	sed -i 's/#wal_buffers = -1/wal_buffers = 1024kB/g' $PG_CONF_FILE
        	sed -i 's/#checkpoint_segments = 3/checkpoint_segments = 32/g' $PG_CONF_FILE
        	sed -i 's/localhost/*/g' $PG_CONF_FILE
        	sed -i 's/#listen_addresses/listen_addresses/g' $PG_CONF_FILE
        	sed -i 's/#checkpoint_completion_target = 0.5/checkpoint_completion_target = 0.9/g' $PG_CONF_FILE
        	sed -i 's/shared_buffers = 24MB/shared_buffers = 256MB/g' $PG_CONF_FILE
        	sed -i 's/#effective_cache_size = 128MB/effective_cache_size = 256MB/g' $PG_CONF_FILE
        	echo  "host    all             all             0.0.0.0/0          trust" >> $PG_DATA_DIR/pg_hba.conf
        else
        	echo "Warning: $PG_DATA_DIR directory exists data, Skip!"
        	continue
        fi
    done
    sudo chown $USER -R /var/run/postgresql
}
pg_start() {
    for ((j=0;j<"$LEN";j++)); do
        PG_DATA_DIR=/data$j/pg
        PG_PORT=$(($BASE_PORT+$j))
        $PG_BIN_DIR/pg_ctl -D $PG_DATA_DIR -l $PG_DATA_DIR/db${j}.log start
    done
}
pg_stop() {
    for ((j=0;j<"$LEN";j++)); do
        PG_DATA_DIR=/data$j/pg
        PG_PORT=$(($BASE_PORT+$j))
        $PG_BIN_DIR/pg_ctl -m fast -D $PG_DATA_DIR stop
    done
}
pg_import_sql() {
	if [ $# -ne 2 ]; then
		echo "Usage: $0 import-sql 'sql_file_path'"	
		exit
	else
		for ((j=0;j<"$LEN";j++)); do
		    PG_PORT=$(($BASE_PORT+$j))
		    $PG_BIN_DIR/psql postgres -f $2 -p $PG_PORT
			if [ $? -ne 0 ]; then
				echo "sql_file_path possible error!"
				exit
			fi
		done
	fi
}
case $1 in
    create-dir)
        create_pg_dir
    ;;
    initdb)
	   pg_initdb
    ;;
    start)
	   pg_start
    ;;
    stop)
	   pg_stop
    ;;
    restart)
	   pg_stop
	   pg_start
    ;;
    import-sql)
	   pg_import_sql $1 $2
    ;;
    *)
    	echo "Usage: $0 {create-dir|initdb|start|stop|restart|import-sql}"
    	echo "Step: create-dir --> initdb --> start --> import-sql"
    ;;
esac
