#!/bin/bash
DOCPATH=/home/mp_abins
export COLUMNS=128

top_mon (){
echo "[`date "+%Y/%m/%d %H:%M:%S"`]" >> $DOCPATH/top-`date "+%m%d"`.log
echo "[`date "+%Y/%m/%d %H:%M:%S"`]" >> $DOCPATH/iotop-`date "+%m%d"`.log
#/usr/bin/top -bcH -d 1 -n 2 | sed '1,/^top/d' >> $DOCPATH/top-`date "+%m%d"`.log
/usr/bin/top -bcH -d 1 -n 2 >> $DOCPATH/top-`date "+%m%d"`.log &
/usr/sbin/iotop -qokt -d 1 -n 2 >> $DOCPATH/iotop-`date "+%m%d"`.log &
}

top_mon ; sleep 25 ; top_mon