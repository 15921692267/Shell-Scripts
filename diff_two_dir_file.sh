#!/bin/bash

SRC_DIR=$1
DST_DIR=$2

if [ $# -ne 2 ]; then
    echo "Usage: no_dir yes_dir"
    exit 
fi

for SRC_FILE_PATH in $(find $SRC_DIR); do
    if [ ! -d $SRC_FILE_PATH ]; then
        SRC_MD5=$(md5sum $SRC_FILE_PATH |awk '{print $1}')
        DST_FILE_PATH=$(echo $SRC_FILE_PATH | sed "/^$SRC_DIR/{s/$SRC_DIR/$DST_DIR/}")
        if [ -f "$DST_FILE_PATH" ]; then
            DST_MD5=$(md5sum $DST_FILE_PATH |awk '{print $1}')
            if [ "$SRC_MD5" == "$DST_MD5" ]; then
                echo -e "$SRC_FILE_PATH \033[32;40m==\033[0m $DST_FILE_PATH"
            else
                echo -e "$SRC_FILE_PATH \033[31;40m!=\033[0m $DST_FILE_PATH"
                echo "Copy: $(cp -fv $DST_FILE_PATH $SRC_FILE_PATH)"
            fi
        else
            echo -e "\033[31;40m$DST_FILE_PATH not exist!\033[0m"
        fi

    fi
done