#!/bin/bash

#主設定
host="59.120.234.87"
user="gc_monitor"
pass="1qaz@WSX"
dbname="monitor"

#這裡用 shell script 指令來取出值,注意變數名稱要和資料庫中資料表的欄位名稱一樣
#Itemid=''
tablename=$1
src_name=$2
src_ip=$3
dest_name=$4
dest_ip=$5
type=$6
subtype=$7
object=$8
value=$9
date=`date +%s`
#------------------------------------------------------------------------------------------------------------------------------

#主程式,關於欄位名稱,會由此腳本自動抓取資料庫中資料表的欄位名稱
temp=`echo "describe $tablename" | mysql -h $host -u "$user" -p"$pass" -P 10306 "$dbname" --skip-reconnect --disable-reconnect --connect-timeout=3 | sed '1d' | awk '{print $1}'`
head="INSERT INTO $tablename VALUES ("
tail=");"
tt=`
for loop in $temp
        do
        eval echo "\'"'\$'$loop"\',"
        done
`
value=`echo "$head$tt$tail"`
sql=`echo "$value" | sed 's/,)/)/g'`
echo "$sql" | mysql -h $host -u "$user" -p"$pass" -P 10306 "$dbname" --skip-reconnect --disable-reconnect --connect-timeout=3
