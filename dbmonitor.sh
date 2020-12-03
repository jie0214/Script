#!/bin/bash
DOCPATH=/home/mp_abins
MAIL=abins@program.com.tw,angel@program.com.tw,rosong@program.com.tw

#system name
#SYSTEM="GC-APP_47.100.166.97"
SYSTEM="GC-APP_$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"

SRC_NAME="GC-APP"
#SRC_IP="47.100.166.97"
SRC_IP=$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)
DEST_NAME="GC-APP"

#"/" disk usage
DISK_CHECK=1
DISK_LIMIT=94

#"/" inode usage
INODE_CHECK=1
INODE_LIMIT=70

#mongos service
MONGOS_CHECK=0

#mongodb service
MONGODB_CHECK=0

#open files
FILES_CHECK=1
FILES_LIMIT=30000

#CPU load average
CPU_CHECK=1
#CPU_LIMIT=10
CPU_LIMIT=15

#swap usage average
SWAP_CHECK=1
SWAP_LIMIT=2500

#network connections
NETCON_CHECK=1
#NETCON_LIMIT=2000
NETCON_LIMIT=6000

#network traffic KB/s
NETTRA_CHECK=0
NETTRAIN_LIMIT=6000
NETTRAOUT_LIMIT=3000

#httpd service
HTTPD_CHECK=0

#nginx service
NGINX_CHECK=0

#apache2 service
APACHE2_CHECK=1

#rabbitMQ queue
RMQ_CHECK=0
RMQ_LIMIT=100000
RMQ_TOTAL=500000
#auto delete if queue of station is over RMQ_LIMIT
RMQ_DELETE=0
#rabbitMQ memory usage
RMQ_MEM_LIMIT=8000000000

#notify by mail, sms and slack
notifym(){
        tail -n 1 $DOCPATH/dbmonitor.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' $SRC_NAME $SRC_IP $DEST_NAME $SRC_IP 'EVENT' 'DBMONITOR' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifym2(){
        tail -n 4 $DOCPATH/dbmonitor.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' $SRC_NAME $SRC_IP $DEST_NAME $SRC_IP 'EVENT' 'DBMONITOR' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifysms(){
        rm -f $DOCPATH/dbmonitor.sql > /dev/null
        for i in `grep "^CN:" $DOCPATH/dbmonitor.txt | sed -e 's/CN://g' -e 's/#.*//g'`
        do
                echo "insert into api_mt_api0207 (SM_ID,SRC_ID,MOBILES,CONTENT,IS_WAP,URL,SEND_TIME,SM_TYPE,MSG_FMT,TP_PID,TP_UDHI,FEE_TERMINAL_ID,FEE_TYPE,FEE_CODE,FEE_USER_TYPE) values (0, 0,'$i','$SUBJECT. `tail -n 1 $DOCPATH/dbmonitor.log`',0,'',null,0,0,0,0,'','','',0);" >> $DOCPATH/dbmonitor.sql
        done

        mysql -h 183.250.132.77 -uapi0207 -papi20170207 mas < $DOCPATH/dbmonitor.sql
        rm -f $DOCPATH/dbmonitor.sql > /dev/null

        for i in `grep "^TW:"  $DOCPATH/dbmonitor.txt | sed -e 's/TW://g' -e 's/#.*//g'`
        do
                wget "http://smexpress.mitake.com.tw:7002/SpLmGet?username=20878766&password=22471899&dstaddr=$i&dlvtime=&vldtime=86400&smbody=$SUBJECT. `tail -n 1 $DOCPATH/dbmonitor.log`" --header="Content-Type: text/javascript; charset=big5" -O /dev/null
        done
}

notifysms2(){
        rm -f $DOCPATH/dbmonitor.sql > /dev/null
        for i in `grep "^CN:" $DOCPATH/dbmonitor.txt | sed -e 's/CN://g' -e 's/#.*//g'`
        do
                echo "insert into api_mt_api0207 (SM_ID,SRC_ID,MOBILES,CONTENT,IS_WAP,URL,SEND_TIME,SM_TYPE,MSG_FMT,TP_PID,TP_UDHI,FEE_TERMINAL_ID,FEE_TYPE,FEE_CODE,FEE_USER_TYPE) values (0, 0,'$i','$SUBJECT. `tail -n 1 $DOCPATH/dbmonitor.log` TOP 3: `tail -n 2 $DOCPATH/dbmonitor.log | head -n 1`, `tail -n 3 $DOCPATH/dbmonitor.log | head -n 1`, `tail -n 4 $DOCPATH/dbmonitor.log | head -n 1`',0,'',null,0,0,0,0,'','','',0);" >> $DOCPATH/dbmonitor.sql
        done

        mysql -h 183.250.132.77 -uapi0207 -papi20170207 mas < $DOCPATH/dbmonitor.sql
        rm -f $DOCPATH/dbmonitor.sql > /dev/null

        for i in `grep "^TW:"  $DOCPATH/dbmonitor.txt | sed -e 's/TW://g' -e 's/#.*//g'`
        do
                wget "http://smexpress.mitake.com.tw:7002/SpLmGet?username=20878766&password=22471899&dstaddr=$i&dlvtime=&vldtime=86400&smbody=$SUBJECT. `tail -n 1 $DOCPATH/dbmonitor.log` TOP 3: `tail -n 2 $DOCPATH/dbmonitor.log | head -n 1`, `tail -n 3 $DOCPATH/dbmonitor.log | head -n 1`, `tail -n 4 $DOCPATH/dbmonitor.log | head -n 1`" --header="Content-Type: text/javascript; charset=big5" -O /dev/null
        done
}

notifyslack(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/dbmonitor.log)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyslack2(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/dbmonitor.log) TOP 3:\n$(tail -n 2 $DOCPATH/dbmonitor.log | head -n 1)\n$(tail -n 3 $DOCPATH/dbmonitor.log | head -n 1)\n$(tail -n 4 $DOCPATH/dbmonitor.log | head -n 1)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyline(){
        #https://notify-bot.line.me/oauth/authorize?response_type=code&client_id=EvH9H06eLVxIUfZlVobZgo&redirect_uri=http://www.google.com.tw&scope=notify&state=NO_STATE
        #curl -X POST -sLk -d "&grant_type=authorization_code&code=$1&redirect_uri=http://www.google.com.tw&client_id=EvH9H06eLVxIUfZlVobZgo&client_secret=9zk3GjwgsFfqsKSEArP8t82lXLJ35OqX0oezL4FBdyo" https://203.104.138.172/oauth/token -w "\n" | cut -d "," -f 3 | sed -e 's/"//g' -e 's/}//g'
        for LINETOKEN in `grep "^LINE:" $DOCPATH/dbmonitor.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT. $(tail -n $COUNTER $DOCPATH/dbmonitor.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT. ; tail -n 1 $DOCPATH/dbmonitor.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/dbmonitor.log
                        fi
                done
        done
}

notifyline2(){
        for LINETOKEN in `grep "^LINE:" $DOCPATH/dbmonitor.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT. $(tail -n $COUNTER $DOCPATH/dbmonitor.log | head -n 1) TOP 3: $(tail -n $(($COUNTER+1)) $DOCPATH/dbmonitor.log | head -n 1), $(tail -n $(($COUNTER+2)) $DOCPATH/dbmonitor.log | head -n 1), $(tail -n $(($COUNTER+3)) $DOCPATH/dbmonitor.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/dbmonitor.log | head -n 1 ; echo TOP 3: ; tail -n 2 $DOCPATH/dbmonitor.log | head -n 1 ; tail -n 3 $DOCPATH/dbmonitor.log | head -n 1 ; tail -n 4 $DOCPATH/dbmonitor.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/dbmonitor.log
                        fi
                done
        done
}

notifywechat (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
        for WECHAT in `grep "^WECHAT:" $DOCPATH/dbmonitor.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/dbmonitor.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$WECHAT $WECHATRESP retry=$COUNTER" >> $DOCPATH/dbmonitor.log
                        fi
                done
        done
}

notifywechat2 (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
        for WECHAT in `grep "^WECHAT:" $DOCPATH/dbmonitor.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/httpd_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 5 $DOCPATH/httpd_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 4 $DOCPATH/httpd_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 3 $DOCPATH/httpd_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 2 $DOCPATH/httpd_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$WECHAT $WECHATRESP retry=$COUNTER" >> $DOCPATH/dbmonitor.log
                        fi
                done
        done
}

notifyevent (){
        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'data_test' $SRC_NAME $SRC_IP $DEST_NAME $SRC_IP 'EVENT' 'DBMONITOR' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

todocker_switch=0

SUBJECT="$SYSTEM monitor service alert"
YMD=$(date +%s)
INT=3600
RUNNING=10
if [ `tail -n $RUNNING $DOCPATH/dbmonitor.log | grep "monitor is still running" | wc -l` -eq $RUNNING ]
then
        U=$(date +%s --date="`tail -n $RUNNING $DOCPATH/dbmonitor.log | head -n 1 | cut -d "]" -f 1 | cut -d "[" -f 2`")
        if [ $(( $YMD - $U )) -le $INT ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] === dbmonitor may not work properly. >> $DOCPATH/dbmonitor.log
                notifym
                notifyline
                notifywechat
        fi
fi

D=`ps -ef | grep dbmonitor.sh | grep -v grep | wc -l`
if [ $D -gt 4 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] === monitor is still running, so exit. >> $DOCPATH/dbmonitor.log
        exit 0
fi

SUBJECT="$SYSTEM disk usage alert"
DISK=`df -h | sed -n '/\/$/p' | awk '{print $5}' | cut -d "%" -f 1`

if [ $DISK_CHECK -eq 1 ] && [ $DISK -ge $DISK_LIMIT ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== disk usage of / is $DISK% (threshold: $DISK_LIMIT%)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
fi

SUBJECT="$SYSTEM inode usage alert"
INODE=`df -ih | sed -n '/\/$/p' | awk '{print $5}' | cut -d "%" -f 1`

if [ $INODE_CHECK -eq 1 ] && [ $INODE -ge $INODE_LIMIT ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== inode usage of / is $INODE% (threshold: $INODE_LIMIT%)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
fi

SUBJECT="$SYSTEM MongoDB query alert"

COUNTER=1
while [ $COUNTER -le 3 ]
do

        if [ $MONGOS_CHECK -eq 1 ] && [ $(mongo --host 127.0.0.1:40000 cps -u mp -p mp --authenticationDatabase=admin --quiet --eval 'printjson(rs.slaveOk());(db.cards.find({card_no:"oVk2Fs6Y_--gE6h_Kf4Uf0kuOCMA"},{card_no:1}).maxTimeMS(3000).toArray())' | grep -c card_no) -lt 1 ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== MongoDB query failed: $COUNTER" >> $DOCPATH/dbmonitor.log
                COUNTER=$(($COUNTER+1))
                if [ $COUNTER -le 3 ]
                then
                        sleep 3
                fi
        else
                break
        fi
done

if [ $COUNTER -gt 3 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== MongoDB query failed." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM mongos service alert"

if [ $MONGOS_CHECK -eq 1 ] && [ `ps -ef | grep mongos | grep -v grep | wc -l` -eq 0 ]
then
        /usr/bin/mongos --config /usr/local/mongodb/srv_config/router.conf
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== mongos restart." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM mongodb service alert"

if [ $MONGODB_CHECK -eq 1 ] && [ `ps -ef | grep "/usr/local/mongodb/srv_config/config.conf" | grep -v grep | wc -l` -eq 0 ]
then
#       /usr/bin/mongod --config /usr/local/mongodb/srv_config/config.conf
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== mongodb-config service alert." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

if [ $MONGODB_CHECK -eq 1 ] && [ `ps -ef | grep "/usr/local/mongodb/srv_config/rs1.conf" | grep -v grep | wc -l` -eq 0 ]
then
        /usr/bin/mongod --config /usr/local/mongodb/srv_config/rs1.conf
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== mongodb-rs1 service restart." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

if [ $MONGODB_CHECK -eq 1 ] && [ `ps -ef | grep "/usr/local/mongodb/srv_config/rs2.conf" | grep -v grep | wc -l` -eq 0 ]
then
        /usr/bin/mongod --config /usr/local/mongodb/srv_config/rs2.conf
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== mongodb-rs2 service restart." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM open files alert"
#FILES=`lsof | wc -l`
FILES=`awk '{print $1}' /proc/sys/fs/file-nr`

if [ $FILES_CHECK -eq 1 ] && [ $FILES -ge $FILES_LIMIT ]
then
#       lsof | awk '{print $1}' | sort | uniq -c | sort -n | tail -n 3 | sed 's/^[ ]*//g' >> $DOCPATH/dbmonitor.log
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of open files is $FILES (threshold: $FILES_LIMIT)." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM CPU load average alert"
CPU=`cut -d " " -f 2 /proc/loadavg`

if [ $CPU_CHECK -eq 1 ] && [ `echo "$CPU >= $CPU_LIMIT"|bc` -eq 1 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== CPU loading is $CPU (threshold: $CPU_LIMIT)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM SWAP usage alert"
SWAP=`free -m | grep -i swap | awk '{print $3}'`

if [ $SWAP_CHECK -eq 1 ] && [ `echo "$SWAP >= $SWAP_LIMIT"|bc` -eq 1 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== SWAP usage is ${SWAP}M (threshold: ${SWAP_LIMIT}M)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
#       notifyline
#       notifywechat
fi

SUBJECT="$SYSTEM network connections alert"
NETCON=`netstat -nut | wc -l`

if [ $NETCON_CHECK -eq 1 ] && [ $NETCON -ge $NETCON_LIMIT ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of network connections is $NETCON (threshold: $NETCON_LIMIT)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
fi

SUBJECT="$SYSTEM network traffic alert"
ifstat -n -T 5 1 | tail -n 1 > $DOCPATH/nettra.log
NETTRA_IN_1=`cat $DOCPATH/nettra.log | awk '{print $1}'`
NETTRA_IN_T=`cat $DOCPATH/nettra.log | awk '{print $3}'`
NETTRA_OUT_1=`cat $DOCPATH/nettra.log | awk '{print $2}'`
NETTRA_OUT_T=`cat $DOCPATH/nettra.log | awk '{print $4}'`

if [ $NETTRA_CHECK -eq 1 ] && [ `echo "$NETTRA_IN_T >= $NETTRAIN_LIMIT" | bc` -eq 1 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== input of network traffic are Internet: $NETTRA_IN_1, Intranet: $NETTRA_IN_2, Total: $NETTRA_IN_T (threshold: $NETTRAIN_LIMIT)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
fi

if [ $NETTRA_CHECK -eq 1 ] && [ `echo "$NETTRA_OUT_T >= $NETTRAOUT_LIMIT" | bc` -eq 1 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== output of network traffic are Internet: $NETTRA_OUT_1, Intranet: $NETTRA_OUT_2, Total: $NETTRA_OUT_T (threshold: $NETTRAOUT_LIMIT)." >> $DOCPATH/dbmonitor.log
        notifym
#       notifysms
        notifyslack
fi
rm -rf $DOCPATH/nettra.log > /dev/null

SUBJECT="$SYSTEM httpd service alert"
HTTPD=/usr/local/httpd/bin/apachectl
HTTPD_BIN=/usr/local/httpd/bin/httpd

if [ $HTTPD_CHECK -eq 1 ] && [ `ps -ef | grep $HTTPD_BIN | grep -v grep | wc -l` -eq 0 ]
then
        $HTTPD start
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== httpd restart." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM nginx service alert"
HTTPD=/etc/init.d/nginx
HTTPD_BIN=/usr/sbin/nginx

if [ $NGINX_CHECK -eq 1 ] && [ `ps -ef | grep $HTTPD_BIN | grep -v grep | wc -l` -eq 0 ]
then
        $HTTPD start
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== nginx restart." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM apache2 service alert"
HTTPD=/usr/sbin/apache2ctl
HTTPD_BIN=/usr/sbin/apache2

if [ $APACHE2_CHECK -eq 1 ] && [ `ps -ef | grep $HTTPD_BIN | grep -v grep | wc -l` -eq 0 ]
then
        $HTTPD start
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== apache2 restart." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM RabbitMQ service alert"
#RMQSRV=`/usr/sbin/rabbitmqctl -q -t 20 list_queues messages_ready | wc -l`
#RMQSRV=$(curl -sLk -w '{code=%{http_code},time=%{time_total}}\n' --connect-timeout 20 -m 20 -u seadmin:se@89798198 'http://localhost:15672/api/healthchecks/node/rabbit@RabbitMQ' | grep -c "ok")
RMQSRV=$(curl -sLk -w '\n' --connect-timeout 10 -m 10 -u seadmin:se@89798198 'http://localhost:15672/api/nodes' -f | jq '.[] | .mem_used' | wc -l)

if [ $RMQ_CHECK -eq 1 ] && [ $RMQSRV -eq 0 ]
then
#       /usr/sbin/rabbitmq-server -detached
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== RabbitMQ service alert." >> $DOCPATH/dbmonitor.log
        notifym
        notifysms
        notifyslack
        notifyline
        notifywechat
fi

SUBJECT="$SYSTEM RabbitMQ queue alert"
#/usr/sbin/rabbitmqctl -q -t 20 list_queues name messages_ready | sed -e 's/0000000000_//g' -e 's/\t/:/g' | sort -b -k 2 -n -t ":" > $DOCPATH/rmq.log
Lk -w '\n' --connect-timeout 10 -m 10 -u seadmin:se@89798198 'http://localhost:15672/api/queues?sort=messages_ready' -f | jq -r '.[] | .name, .messages_ready' | sed -e '/$/{N;s/\n/:/}' -e 's/0000000000_//g' > $DOCPATH/rmq.log
RMQ=`awk -F ":" '{s+=$2} END {printf "%.0f", s}' $DOCPATH/rmq.log`

if [ $RMQ_CHECK -eq 1 ] && [ $RMQ -lt $RMQ_TOTAL ]
then
        if [ -e $DOCPATH/rmq_total.log ]
        then
                rm $DOCPATH/rmq_total.log 2>/dev/null
#               notifym2
#               notifysms2
#               notifyslack2
#               notifyline2
#               notifywechat2
        fi

#elif [ $RMQ_CHECK -eq 1 ] && [ $RMQ -ge $RMQ_LIMIT1 ] && [ $RMQ -lt $RMQ_LIMIT2 ]
#then
#       tail -n 3 $DOCPATH/rmq.log >> $DOCPATH/dbmonitor.log
#       echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of RabbitMQ queue is $RMQ." >> $DOCPATH/dbmonitor.log
#       rm $DOCPATH/rmq_limit2.log 2>/dev/null
#       if [ ! -e $DOCPATH/rmq_limit1.log ]
#       then
#               touch $DOCPATH/rmq_limit1.log
##              notifym2
##              notifysms2
##              notifyslack2
#       fi

elif [ $RMQ_CHECK -eq 1 ] && [ $RMQ -ge $RMQ_TOTAL ]
then
        tail -n 3 $DOCPATH/rmq.log >> $DOCPATH/dbmonitor.log
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of RabbitMQ queue is $RMQ (threshold: $RMQ_TOTAL)." >> $DOCPATH/dbmonitor.log
#       rm $DOCPATH/rmq_limit1.log 2>/dev/null
        if [ ! -e $DOCPATH/rmq_total.log ]
        then
                touch $DOCPATH/rmq_total.log
                notifym2
#               notifysms2
#               notifyslack2
#               notifyline2
#               notifywechat2
#       else
#               notifym2
#               notifysms2
#               notifyslack2
        fi
fi

SUBJECT="$SYSTEM RabbitMQ queue had been deleted"
        for R in `grep -v -e ":0" -e r_mqueue -e xps_cmds $DOCPATH/rmq.log`
        do
                RMQ_S1=`echo $R | awk -F ":" '{print $1}'`
                RMQ_S2=`echo $RMQ_S1 | cut -d "_" -f 1`
                RMQ_S3=`echo $RMQ_S1 | cut -d "." -f 1`
                RMQ_Q=`echo $R | awk -F ":" '{print $2}'`
                if [ $RMQ_DELETE -eq 1 ] && [ $RMQ_Q -gt $RMQ_LIMIT ]
                then
#                       /usr/sbin/rabbitmqctl purge_queue "0000000000_$RMQ_S2"_cards
#                       /usr/sbin/rabbitmqctl purge_queue "0000000000_$RMQ_S2"_cmds
                        curl -sLk -w "\n" -X DELETE -u seadmin:se@89798198 'http://localhost:15672/api/queues/%2F/0000000000_'$RMQ_S2'_cards'
#                       curl -sLk -w "\n" -d 'sid=accd5d67cec0822c97a9d846ecda7fc06e00b036&data={"s_no":"'$RMQ_S3'"}' https://192.168.101.1/api/ubikeV3/removexpscarddb
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Queue in $RMQ_S1 is $RMQ_Q (threshold: $RMQ_LIMIT). $RMQ_S1 had been deleted." >> $DOCPATH/dbmonitor.log
                        notifym
#                       notifysms
#                       notifyslack
#                       notifyline
#                       notifywechat
                fi
        done

SUBJECT="$SYSTEM RabbitMQ memory usage alert"
#RMQ_MEM=`/usr/sbin/rabbitmqctl -q -t 20 status | grep total, | cut -d "," -f 2 | cut -d "}" -f 1`
RMQ_MEM=$(curl -sLk -w '\n' --connect-timeout 10 -m 10 -u seadmin:se@89798198 'http://localhost:15672/api/nodes' -f | jq '.[] | .mem_used')
RMQ_MEM2=`echo $RMQ_MEM | numfmt --to=iec`

if [ $RMQ_CHECK -eq 1 ] && [ $RMQ_MEM -gt $RMQ_MEM_LIMIT ]
then
        tail -n 3 $DOCPATH/rmq.log >> $DOCPATH/dbmonitor.log
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== RabbitMQ memory usage is $RMQ_MEM2 (threshold: $(echo $RMQ_MEM_LIMIT | numfmt --to=iec)). Account of RabbitMQ queue is $RMQ." >> $DOCPATH/dbmonitor.log
        notifym2
        notifysms2
        notifyslack2
        notifyline2
        notifywechat2
fi
rm -f $DOCPATH/rmq.log > /dev/null
