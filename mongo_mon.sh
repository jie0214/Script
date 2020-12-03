#!/bin/bash
DOCPATH=/home/mp_abins
MAIL=abins@program.com.tw,mis@program.com.tw,angel@program.com.tw,rosong@program.com.tw,wang@program.com.tw

#system name
#SYSTEM="(Detected from GC-APP_$(grep address /etc/network/interfaces | awk '{print $2}' | head -n 1)) CN-MongoDB"

#SRC_NAME="GC-APP"
#SRC_IP=$(grep address /etc/network/interfaces | awk '{print $2}' | head -n 1)

#SYSTEM=".(Detected from GC-APP_47.100.166.97) GC-MongoDB"
SYSTEM=".(Detected from GC-APP_$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)) GC-MongoDB"

SRC_NAME="GC-APP"
#SRC_IP="47.100.166.97"
SRC_IP="$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"

notifym (){
        tail -n 1 $DOCPATH/mongo_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) 'EVENT' 'MONGO_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifym2 (){
        tail -n 5 $DOCPATH/mongo_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) 'EVENT' 'MONGO_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifyslack(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/mongo_mon.log)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyslack2(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/mongo_mon.log) TOP 3:\n$(tail -n 2 $DOCPATH/mongo_mon.log | head -n 1)\n$(tail -n 3 $DOCPATH/mongo_mon.log | head -n 1)\n$(tail -n 4 $DOCPATH/mongo_mon.log | head -n 1)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyline(){
        #https://notify-bot.line.me/oauth/authorize?response_type=code&client_id=EvH9H06eLVxIUfZlVobZgo&redirect_uri=http://www.google.com.tw&scope=notify&state=NO_STATE
        #curl -X POST -sLk -d "&grant_type=authorization_code&code=$1&redirect_uri=http://www.google.com.tw&client_id=EvH9H06eLVxIUfZlVobZgo&client_secret=9zk3GjwgsFfqsKSEArP8t82lXLJ35OqX0oezL4FBdyo" https://203.104.138.172/oauth/token -w "\n" | cut -d "," -f 3 | sed -e 's/"//g' -e 's/}//g'
        for LINETOKEN in `grep "^LINE:" $DOCPATH/mongo_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/mongo_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/mongo_mon.log
                        fi
                done
        done
}

notifyline2(){
        for LINETOKEN in `grep "^LINE:" $DOCPATH/mongo_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/mongo_mon.log | head -n 1 ; tail -n 5 $DOCPATH/mongo_mon.log | head -n 1 ; tail -n 4 $DOCPATH/mongo_mon.log | head -n 1 ; tail -n 3 $DOCPATH/mongo_mon.log | head -n 1 ; tail -n 2 $DOCPATH/mongo_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/mongo_mon.log
                        fi
                done
        done
}

notifywechat (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
        for WECHAT in `grep "^WECHAT:" $DOCPATH/mongo_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/mongo_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
                        fi
                done
        done
}

notifywechat2 (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
        for WECHAT in `grep "^WECHAT:" $DOCPATH/mongo_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/mongo_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 5 $DOCPATH/mongo_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 4 $DOCPATH/mongo_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 3 $DOCPATH/mongo_mon.log | head -n 1 | sed 's/"/\\"/g' ; tail -n 2 $DOCPATH/mongo_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
                        fi
                done
        done
}

mongo_mon (){
        /usr/bin/mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval 'printjson(db.serverStatus())' > $DOCPATH/mongo_mon2.log

        if [ $? -eq 1 ]
        then
                rm -r $DOCPATH/mongo_mon2.log > /dev/null
#               echo [`date "+%Y/%m/%d %H:%M:%S"`] === $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1):$RS was down. >> $DOCPATH/mongo_mon.log
                echo [`date "+%Y/%m/%d %H:%M:%S"`] === $HOST2 was down. >> $DOCPATH/mongo_mon.log
                notifym
#               notifyslack
                notifyline
                notifywechat

#               rm -rf $DOCPATH/mongo_mon.lck > /dev/null 2>&1
                return 0
        fi

        MONGO_TICKETS_READ=$(grep -A10 concurrentTransactions $DOCPATH/mongo_mon2.log | grep -A2 read | grep available | cut -d " " -f 3 | cut -d "," -f 1)
        MONGO_TICKETS_WRITE=$(grep -A10 concurrentTransactions $DOCPATH/mongo_mon2.log | grep -A2 write | grep available | cut -d " " -f 3 | cut -d "," -f 1)


COUNTER=1
while [ $COUNTER -le 3 ]
do
        /usr/bin/mongostat --host $HOST -u root -p Bbbbb11111 --authenticationDatabase=admin -n 1 5 --noheaders > $DOCPATH/mongo_mon2.log
        MONGO_INSERT=$(awk '{print $1}' $DOCPATH/mongo_mon2.log | sed 's/\*//g')
        MONGO_QUERY=$(awk '{print $2}' $DOCPATH/mongo_mon2.log | sed 's/\*//g')
        MONGO_UPDATE=$(awk '{print $3}' $DOCPATH/mongo_mon2.log | sed 's/\*//g')
        MONGO_DELETE=$(awk '{print $4}' $DOCPATH/mongo_mon2.log | sed 's/\*//g')
        MONGO_GETMORE=$(awk '{print $5}' $DOCPATH/mongo_mon2.log | sed 's/\*//g')
        MONGO_COMMAND=$(awk '{print $6}' $DOCPATH/mongo_mon2.log | sed 's/\*//g' | cut -d "|" -f 1)
        MONGO_QUEUE_READ=$(awk '{print $12}' $DOCPATH/mongo_mon2.log | sed 's/\*//g' | cut -d "|" -f 1)
        MONGO_QUEUE_WRITE=$(awk '{print $12}' $DOCPATH/mongo_mon2.log | sed 's/\*//g' | cut -d "|" -f 2)
        MONGO_QUEUE_ALL=$(($MONGO_QUEUE_READ + $MONGO_QUEUE_WRITE))
        MONGO_NETIN=$(awk '{print $14}' $DOCPATH/mongo_mon2.log)
        MONGO_NETOUT=$(awk '{print $15}' $DOCPATH/mongo_mon2.log)
        MONGO_CONNECTIONS=$(awk '{print $16}' $DOCPATH/mongo_mon2.log | sed 's/\*//g')

        if [ $MONGO_QUEUE_ALL -le $QUEUE_LIMIT ]
        then
                resp_mon
                break
        else
                resp_mon
#               echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1):$RS queue is $MONGO_QUEUE_ALL." >> $DOCPATH/mongo_mon.log
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $HOST2 queue is $MONGO_QUEUE_ALL." >> $DOCPATH/mongo_mon.log
                COUNTER=$(($COUNTER+1))
                if [ $COUNTER -le 3 ]
                then
                        sleep $RETRYINT
                fi
        fi
done

if [ $COUNTER -gt 3 ] && [ $MONGO_QUEUE_ALL -gt $QUEUE_LIMIT ]
then
        notifym
#       notifyslack
        notifyline
        notifywechat
fi
}

mongo_slow (){
        DATE=$(($(date +%s)-$(($SLOW_INT*60))))
#       /usr/bin/mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval '(rs.slaveOk());(db.system.profile.find({ts:{$gt: ISODate("'$(date -u -Iseconds -d @$DATE)'")},ns:{$nin:["'$DB'.system.profile"]}},{op:1,ns:1,millis:1,client:1}).sort({millis:-1}).toArray())' | awk 1 ORS=' ' | sed -e 's/},/},\n/g' | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g' | awk '{print $4,$7,$10,$13}' | sed -e 's/ //g' > $DOCPATH/mongo_mon2.log
        /usr/bin/mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval '(rs.slaveOk());(db.system.profile.find({ts:{$gt: ISODate("'$(date -u -Iseconds -d @$DATE)'")},ns:{$ne:"'$DB'.system.profile"},millis:{$gt:1000}},{op:1,ns:1,millis:1,client:1}).sort({millis:-1}).toArray())' | awk 1 ORS=' ' | sed -e 's/},/},\n/g' | sed -e 's/\[//g' -e 's/\]//g' -e 's/\"//g' | awk '{print $4,$7,$10,$13}' | sed -e 's/ //g' > $DOCPATH/mongo_mon2.log
        MONGO_SLOW=$(grep -c "," $DOCPATH/mongo_mon2.log)
#       MONGO_CUR_TOTAL=$(/usr/bin/mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval 'printjson(db.currentOp({"secs_running":{$gt:'$CUR_LIMIT'}, ns:{$nin:["local.oplog.rs","local.replset.minvalid"]}}).inprog.length)')
        MONGO_CUR=$(/usr/bin/mongo --host $HOST -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval 'printjson(db.currentOp({"secs_running":{$gt:'$CUR_LIMIT'}, "ns":/'$DB'.*/}).inprog.length)')

        resp_mon2

#       MONGO_SLOWEST=$(/usr/bin/mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval '(rs.slaveOk());(db.system.profile.find({ts:{$gt: ISODate("'$(date -u -Iseconds -d @$DATE)'")}},{op:1,millis:1,client:1}).sort({millis:-1}).limit(3).pretty())' | cut -d " " -f 4,7,10 | awk 1 ORS='' | sed -e 's/$/,/' -e 's/, /:/g' -e 's/""/,/g' -e 's/"//g')
#       for SLOW_IP in $(cut -d "," -f 3 $DOCPATH/mongo_mon2.log | sort -V | uniq)
        for SLOW_IP in $(cut -d "," -f 4 $DOCPATH/mongo_mon2.log | sort -V | uniq)
        do
                for MONGO_SLOWEST in $(grep $SLOW_IP$ $DOCPATH/mongo_mon2.log | head -n 3)
                do
                        SLOW_OP=$(echo $MONGO_SLOWEST | cut -d "," -f 1)
                        SLOW_NS=$(echo $MONGO_SLOWEST | cut -d "," -f 2)
                        SLOW_TIMEORG=$(echo $MONGO_SLOWEST | cut -d "," -f 3)
                        SLOW_TIME=$(echo $MONGO_SLOWEST | cut -d "," -f 3 | awk '{printf ("%.3f\n",$1/1000)}')
#                       SLOW1_IP=$(echo $MONGO_SLOWEST | cut -d "," -f 4)

                        resp_mon3
                done
        done
        echo "" >> $DOCPATH/mongo_mon.log
}

mongo_rep (){
        /usr/bin/mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval 'printjson(rs.status())' > $DOCPATH/mongo_mon2.log
        REPL_STATE="$(grep -A2 $HOST2 $DOCPATH/mongo_mon2.log | grep '"state"' | awk '{print $3}' | cut -d "," -f 1)"
        REPL_IP="$(grep name $DOCPATH/mongo_mon2.log | grep $HOST2 | awk '{print $3}' | sed -e 's/"//g' -e 's/,//g')"
        REPL_IP2="$(grep name $DOCPATH/mongo_mon2.log | grep -v $HOST2 | awk '{print $3}' | sed -e 's/"//g' -e 's/,//g')"
        REPL_TIME="$(grep -A6 $HOST2 $DOCPATH/mongo_mon2.log | grep ts | cut -d "(" -f 2 | cut -d "," -f 1)"
        REPL_TIME2="$(grep -v $HOST2 $DOCPATH/mongo_mon2.log | grep -A6 name | grep ts | cut -d "(" -f 2 | cut -d "," -f 1)"
        MONGO_IP=($REPL_IP $REPL_IP2)
        MONGO_TIME=($REPL_TIME $REPL_TIME2)
        MONGO_NUM=$(grep -c '"name"' $DOCPATH/mongo_mon2.log)

        resp_mon4

        for i in `seq 1 $(($MONGO_NUM-1))`
        do
                if [ ${MONGO_TIME[0]} != 0 ] && [ ${MONGO_TIME[$i]} != 0 ]
                then
                        REPL_T="$((${MONGO_TIME[0]}-${MONGO_TIME[$i]}))"
                        if [ `echo "$REPL_T > $REPL_LIMIT" | bc` -eq 1 ]
                        then
                                echo "[`date "+%Y/%m/%d %H:%M:%S"`] === ${MONGO_IP[$i]}-${MONGO_IP[0]} replcation was delayed for $(echo $REPL_T | tr -d "-")s." >> $DOCPATH/mongo_mon.log
                                notifym
#                               notifyslack
                                notifyline
                                notifywechat

                        fi
                        resp_mon5
                fi
        done

        echo "" >> $DOCPATH/mongo_mon.log
}

mongo_pool (){
#       mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval 'printjson(rs.slaveOk());(db.runCommand({"connPoolStats":1}))' | sed '/hosts/Q' > $DOCPATH/mongo_mon2.log
#       MONGO_NUM=$(($(echo $DB_IP | grep -o ":" | wc -l)))
#       DBS=($DB_IP)
#       MONGO_CORE=$(grep -c TaskExecutorPool $DOCPATH/mongo_mon2.log)
#       for i in `seq 0 $(($MONGO_NUM-1))`
#       do
#               if [ ! -z ${DBS[$i]} ]
#               then
#                       MONGO_POOL=$(grep -A 2 "${DBS[$i]}" $DOCPATH/mongo_mon2.log | grep -c 'available" : 0')
#                       resp_mon6
#               fi
#       done

        for DBS in $(mongo --host $HOST $DB -u root -p Bbbbb11111 --authenticationDatabase=admin --quiet --eval 'printjson(rs.slaveOk());(db.runCommand({"connPoolStats":1}))' | sed -n '/ShardRegistry/,$!d; /TaskExecutorPool/q; p' | grep -B 2 'available" :' | sed -e '/inUse/d' | sed ":a;N;s/{\n//g;ta" | cut -d '"' -f 2,5 | sed -e 's/" : /,/g' -e 's/,$//g' -e '/--/d')
        do
                DBS_IP=$(echo $DBS | cut -d "," -f 1)
                MONGO_POOL=$(echo $DBS | cut -d "," -f 2)
                resp_mon6
        done

        echo "" >> $DOCPATH/mongo_mon.log
}

resp_mon (){
#       echo "[`date "+%Y/%m/%d %H:%M:%S"`] $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1):$RS-$DB tickets_r: $MONGO_TICKETS_READ, tickets_w: $MONGO_TICKETS_WRITE, insert: $MONGO_INSERT, query: $MONGO_QUERY, update: $MONGO_UPDATE, delete: $MONGO_DELETE, getmore: $MONGO_GETMORE, command: $MONGO_COMMAND, queue_r: $MONGO_QUEUE_READ, queue_w: $MONGO_QUEUE_WRITE, queue_t: $MONGO_QUEUE_ALL, connections: $MONGO_CONNECTIONS" >> $DOCPATH/mongo_mon.log
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST2-$DB tickets_r: $MONGO_TICKETS_READ, tickets_w: $MONGO_TICKETS_WRITE, insert: $MONGO_INSERT, query: $MONGO_QUERY, update: $MONGO_UPDATE, delete: $MONGO_DELETE, getmore: $MONGO_GETMORE, command: $MONGO_COMMAND, queue_r: $MONGO_QUEUE_READ, queue_w: $MONGO_QUEUE_WRITE, queue_t: $MONGO_QUEUE_ALL, connections: $MONGO_CONNECTIONS" >> $DOCPATH/mongo_mon.log

        if [ $todocker_switch -eq 1 ]
        then
#               bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) $TYPE 'RESP_STATUS' $DEST_NAME $RESP_CODE > /dev/null 2>&1
#               bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$DB" tickets_w $MONGO_TICKETS_WRITE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" tickets_w $MONGO_TICKETS_WRITE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" tickets_r $MONGO_TICKETS_READ > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" insert $MONGO_INSERT > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" query $MONGO_QUERY > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" update $MONGO_UPDATE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" delete $MONGO_DELETE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" getmore $MONGO_GETMORE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" command $MONGO_COMMAND > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" queue_r $MONGO_QUEUE_READ > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" queue_w $MONGO_QUEUE_WRITE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" queue_t $MONGO_QUEUE_ALL > /dev/null 2>&1
#               bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" net_in $MONGO_NETIN > /dev/null 2>&1
#               bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" net_out $MONGO_NETOUT > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" connections $MONGO_CONNECTIONS > /dev/null 2>&1
        fi
}

resp_mon2 (){
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST2-$DB slow_op: $MONGO_SLOW" >> $DOCPATH/mongo_mon.log
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST2-$DB slow_current: $MONGO_CUR" >> $DOCPATH/mongo_mon.log
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST2-$DB slowest_op:" >> $DOCPATH/mongo_mon.log

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$DB" slow_op $MONGO_SLOW > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$DB" slow_current $MONGO_CUR > /dev/null 2>&1
        fi
}

resp_mon3 (){
        if [ ! -z $SLOW_OP ]
        then
                echo "$SLOW_IP-$SLOW_OP-$SLOW_NS $DB: $SLOW_TIME" >> $DOCPATH/mongo_mon.log
                if [ $todocker_switch -eq 1 ]
                then
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB_SLOW "$DB" "$SLOW_IP-$SLOW_OP-$SLOW_NS" "$SLOW_TIMEORG" > /dev/null 2>&1
                        sleep 1
                fi

        fi
}

resp_mon4 (){
#       echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST2-$DB state: $REPL_STATE" >> $DOCPATH/mongo_mon.log
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST2 state: $REPL_STATE" >> $DOCPATH/mongo_mon.log

        if [ $todocker_switch -eq 1 ]
        then
#               bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$DB" state $REPL_STATE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $HOST2 MONGODB "$HOST2" state $REPL_STATE > /dev/null 2>&1
        fi
}

resp_mon5 (){
#       echo "[`date "+%Y/%m/%d %H:%M:%S"`] ${MONGO_IP[0]}-${MONGO_IP[$i]} $DB: $REPL_T" >> $DOCPATH/mongo_mon.log
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] ${MONGO_IP[0]}-${MONGO_IP[$i]} $HOST2: $REPL_T" >> $DOCPATH/mongo_mon.log

        if [ $todocker_switch -eq 1 ]
        then
#               bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) "${MONGO_IP[0]}-${MONGO_IP[$i]}" "$DB" repl_time $REPL_T > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) "${MONGO_IP[0]}-${MONGO_IP[$i]}" "$HOST2" repl_time $REPL_T > /dev/null 2>&1
        fi
}

resp_mon6 (){
#       if [ $MONGO_POOL != 0 ]
#       then
#               echo "[`date "+%Y/%m/%d %H:%M:%S"`] $DEST_NAME-$MONGO_CORE ${DBS[$i]} pool_0: $MONGO_POOL" >> $DOCPATH/mongo_mon.log
#       fi
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] $DEST_NAME $DBS_IP pool: $MONGO_POOL" >> $DOCPATH/mongo_mon.log

        if [ $todocker_switch -eq 1 ]
        then
#               bash $DOCPATH/todocker_test.sh $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) MONGO_POOL "$DEST_NAME-$MONGO_CORE" "${DBS[$i]}" "$MONGO_POOL" > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) MONGO_POOL "$DEST_NAME" "$DBS_IP" "$MONGO_POOL" > /dev/null 2>&1
        fi
}

SUBJECT="$SYSTEM performance monitor service alert"
YMD=$(date +%s)
INT=3600
RUNNING=10
if [ `tail -n $RUNNING $DOCPATH/mongo_mon.log | grep "monitor is still running" | wc -l` -eq $RUNNING ]
then
        U=$(date +%s --date="`tail -n $RUNNING $DOCPATH/mongo_mon.log | head -n 1 | cut -d "]" -f 1 | cut -d "[" -f 2`")
        if [ $(( $YMD - $U )) -le $INT ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] === mongo_mon may not work properly. >> $DOCPATH/mongo_mon.log
#               notifym
#               notifyslack
                notifyline
                notifywechat
        fi
fi

#PS=$(ps -ef | grep mongo_mon.sh | grep -c -v grep)
#if [ $PS -gt 6 ]
if [ $(ps -ef | grep mongo_mon.sh | grep -c -v grep ) -le 3 ]
then
        rm -rf $DOCPATH/mongo_mon.lck > /dev/null 2>&1
fi

if [ -f $DOCPATH/mongo_mon.lck ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] === monitor is still running, so exit. $PS>> $DOCPATH/mongo_mon.log
        exit 0
fi

touch $DOCPATH/mongo_mon.lck
todocker_switch=1

SUBJECT="$SYSTEM performance alert."
HOST="dds-uf6335557d7ca7142878.mongodb.rds.aliyuncs.com:3717"
#HOST="dds-uf6335557d7ca7142680-pub.mongodb.rds.aliyuncs.com:3717"
HOST2="primaryNode"
DEST_NAME="GC-MongoDB1"
#RS=rs1
DB=ridelife
QUEUE_LIMIT=10
SLOW_INT=5
CUR_LIMIT=60
REPL_LIMIT="300"
RETRYINT=10
mongo_mon
mongo_slow
mongo_rep

SUBJECT="$SYSTEM performance alert."
HOST="dds-uf6335557d7ca7141688.mongodb.rds.aliyuncs.com:3717"
#HOST="dds-uf6335557d7ca7141881-pub.mongodb.rds.aliyuncs.com:3717"
HOST2="secondaryNode"
DEST_NAME="GC-MongoDB2"
#RS=rs1
DB=ridelife
QUEUE_LIMIT=10
SLOW_INT=5
CUR_LIMIT=10
REPL_LIMIT="300"
RETRYINT=10
mongo_mon
mongo_slow
mongo_rep

echo "=========================" >> $DOCPATH/mongo_mon.log
rm -rf $DOCPATH/mongo_mon.lck $DOCPATH/mongo_mon2.log > /dev/null 2>&1
