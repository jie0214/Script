#!/bin/bash
DOCPATH=/home/mp_abins
MAIL=abins@program.com.tw

#system name
#SYSTEM="GC-APP_$(grep -A2 ens160 /etc/netplan/50-cloud-init.yaml | tail -n 1 | awk '{print $2}' | cut -d "/" -f 1)"
#SYSTEM2="GC-APP"
#IP2=$(grep -A2 ens160 /etc/netplan/50-cloud-init.yaml | tail -n 1 | awk '{print $2}' | cut -d "/" -f 1)

SYSTEM="GC-APP_172.19.71.77"
SYSTEM2="GC-APP"
IP2="172.19.71.77"

notifym (){
#       tail -n 1 $DOCPATH/php_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'EVENT' 'HIT_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifym2 (){
#       tail -n 5 $DOCPATH/php_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'EVENT' 'HIT_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifyslack(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/php_mon.log)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyslack2(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/php_mon.log) TOP 3:\n$(tail -n 2 $DOCPATH/php_mon.log | head -n 1)\n$(tail -n 3 $DOCPATH/php_mon.log | head -n 1)\n$(tail -n 4 $DOCPATH/php_mon.log | head -n 1)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyline(){
        #https://notify-bot.line.me/oauth/authorize?response_type=code&client_id=EvH9H06eLVxIUfZlVobZgo&redirect_uri=http://www.google.com.tw&scope=notify&state=NO_STATE
        #curl -X POST -sLk -d "&grant_type=authorization_code&code=$1&redirect_uri=http://www.google.com.tw&client_id=EvH9H06eLVxIUfZlVobZgo&client_secret=9zk3GjwgsFfqsKSEArP8t82lXLJ35OqX0oezL4FBdyo" https://203.104.138.172/oauth/token -w "\n" | cut -d "," -f 3 | sed -e 's/"//g' -e 's/}//g'
        for LINETOKEN in `grep "^LINE:" $DOCPATH/hit_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/php_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/php_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/php_mon.log
                        fi
                done
        done
}

notifyline2(){
        for LINETOKEN in `grep "^LINE:" $DOCPATH/hit_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/php_mon.log | head -n 1) TOP3: $(tail -n $(($COUNTER+1)) $DOCPATH/php_mon.log | head -n 1), $(tail -n $(($COUNTER+2)) $DOCPATH/php_mon.log | head -n 1), $(tail -n $(($COUNTER+3)) $DOCPATH/php_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/php_mon.log | head -n 1 ; echo TOP 3: ; tail -n 2 $DOCPATH/php_mon.log | head -n 1 ; tail -n 3 $DOCPATH/php_mon.log | head -n 1 ; tail -n 4 $DOCPATH/php_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/php_mon.log
                        fi
                done
        done
}

notifywechat (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
          for WECHAT in `grep "^WECHAT:" $DOCPATH/hit_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
          do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/php_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
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
        for WECHAT in `grep "^WECHAT:" $DOCPATH/hit_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/php_mon.log | head -n 1 | sed 's/"/\\"/g' ; echo TOP 3: ; echo $(tail -n 2 $DOCPATH/php_mon.log | head -n 1 | sed 's/"/\\"/g') ; echo $(tail -n 3 $DOCPATH/php_mon.log | head -n 1 | sed 's/"/\\"/g') ; echo $(tail -n 4 $DOCPATH/php_mon.log | head -n 1 | sed 's/"/\\"/g'))"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
                        fi
                done
        done
}

php_mon (){
#COUNTER=1
#while [ $COUNTER -le 3 ]
#do
        RESP_API=$(curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "$POST" "$HOST/$API" -f)
        RESP_API2=$(echo $RESP_API | grep "total" | wc -l)
        RESP_CODE=$(echo $RESP_API | awk -F "code=" '{print $2}' | cut -d "," -f 1)
        RESP_TIME=$(echo $RESP_API | awk -F "time=" '{print $2}' | cut -d "}" -f 1)

        if [ $RESP_API2 == 1 ]
        then
                ACC=$(echo $RESP_API | grep "total" | awk -F 'active processes: '  '{print $2}' | awk '{print $1}')
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] $API processes: $ACC" >> $DOCPATH/php_mon.log

                if [ $todocker_switch -eq 1 ]
                then
                        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_API' '' $API $ACC > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" "HTTPD(API)" 'RESP_STATUS' $API $RESP_CODE > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" "HTTPD(API)" 'RESP_TIME' $API $RESP_TIME > /dev/null 2>&1
                fi

                if [ $ACC -gt $LIMIT ]
                then
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $API processes is $ACC (threshold: $LIMIT)." >> $DOCPATH/php_mon.log
                        notifym
                        notifyline
#                       notifywechat

#                       curl -sLk -w "\n" 'https://app.giant.com.cn/fpm-status?full' >> $DOCPATH/php_mon.log
                fi

#               break

        else
#               COUNTER=$(($COUNTER+1))
#               if [ $COUNTER -le 3 ]
#               then
#                       sleep $RETRYINT
#               fi
#       fi
#done

#if [ $COUNTER -gt 3 ] && [ $RESP_API2 != 1 ]
#then
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] === Connecting to API \"$HOST/$API\" may not work properly." >> $DOCPATH/php_mon.log
        notifym
#       notifyline
#       notifywechat
#       exit 0

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" "HTTPD(API)" 'RESP_STATUS' $API $RESP_CODE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" "HTTPD(API)" 'RESP_TIME' $API $RESP_TIME > /dev/null 2>&1
        fi

fi
}

todocker_switch=1

PS=`ps -ef | grep php_mon.sh | grep -v grep | wc -l`
#echo "PS: $PS" >> $DOCPATH/php_mon.log
if [ $PS -gt 4 ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] === monitor is still running, so exit. $PS >> $DOCPATH/php_mon.log
        exit 0
fi

HOST=http://app.giant.com.cn
SUBJECT="$SYSTEM API \"fpm-status\" processes exceed limit."
API="fpm-status"
POST=""
TIMEOUT=5
RETRYINT=3
LIMIT=50
#php_mon;sleep 15;php_mon;sleep 15;php_mon;sleep 10;php_mon
php_mon;sleep 30;php_mon
