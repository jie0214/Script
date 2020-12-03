#!/bin/bash
DOCPATH=/home/mp_abins
MAIL=abins@program.com.tw,angel@program.com.tw,rosong@program.com.tw

#system name
#SYSTEM="GC-APP_$(grep -A2 ens160 /etc/netplan/50-cloud-init.yaml | tail -n 1 | awk '{print $2}' | cut -d "/" -f 1)"
#SYSTEM2="GC-APP"
#IP2=$(grep -A2 ens160 /etc/netplan/50-cloud-init.yaml | tail -n 1 | awk '{print $2}' | cut -d "/" -f 1)

SYSTEM="GC-APP_$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"
SYSTEM2="GC-APP"
IP2="$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"

notifym (){
        tail -n 1 $DOCPATH/hit_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'EVENT' 'HTTPD_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifym2 (){
        tail -n 5 $DOCPATH/hit_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'EVENT' 'HIT_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifyslack(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/hit_mon.log)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyslack2(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/hit_mon.log) TOP 3:\n$(tail -n 2 $DOCPATH/hit_mon.log | head -n 1)\n$(tail -n 3 $DOCPATH/hit_mon.log | head -n 1)\n$(tail -n 4 $DOCPATH/hit_mon.log | head -n 1)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
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
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/hit_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/hit_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/hit_mon.log
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
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/hit_mon.log | head -n 1) TOP3: $(tail -n $(($COUNTER+1)) $DOCPATH/hit_mon.log | head -n 1), $(tail -n $(($COUNTER+2)) $DOCPATH/hit_mon.log | head -n 1), $(tail -n $(($COUNTER+3)) $DOCPATH/hit_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/hit_mon.log | head -n 1 ; echo TOP 3: ; tail -n 2 $DOCPATH/hit_mon.log | head -n 1 ; tail -n 3 $DOCPATH/hit_mon.log | head -n 1 ; tail -n 4 $DOCPATH/hit_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/hit_mon.log
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
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/hit_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
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
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/hit_mon.log | head -n 1 | sed 's/"/\\"/g' ; echo TOP 3: ; echo $(tail -n 2 $DOCPATH/hit_mon.log | head -n 1 | sed 's/"/\\"/g') ; echo $(tail -n 3 $DOCPATH/hit_mon.log | head -n 1 | sed 's/"/\\"/g') ; echo $(tail -n 4 $DOCPATH/hit_mon.log | head -n 1 | sed 's/"/\\"/g'))"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
                        fi
                done
        done
}

statuslog (){
        echo CPU loading is `cut -d " " -f 2 /proc/loadavg` >> $DOCPATH/hit_mon.log
        echo "Account of HTTPD is `ps -ef | grep $HTTPD_BIN | grep -v grep | wc -l`" >> $DOCPATH/hit_mon.log
        echo "Account of network connections is `netstat -nut | wc -l`" >> $DOCPATH/hit_mon.log
        echo "Network traffic: `ifstat -T 5 1 | tail -n 1 | awk '{print "in:"$3" ""out:"$4}'`" >> $DOCPATH/hit_mon.log
}

hit_mon (){
#LOG=/usr/local/youbike/logs/weblogs/$API/$DAY
#LOG2=/usr/local/youbike/logs/weblogs/$API/$DAY2
LOG=/var/log/apache2/access.log
LOG2=/var/log/apache2/access.log.1

if [ ! $DAY -eq $DAY2 ]
then
        nice -n 19 awk '{print $1" "$4" "$7" "$10" "$11}' $LOG2 $LOG | awk -F '[' '{if (($2>="'$DAY2'/'$MONTHR2'/'$YEAR2':'$HOUR2':'$MIN2':'$SEC2'")&&($2<="'$DAY'/'$MONTHR'/'$YEAR':'$HOUR':'$MIN':'$SEC'")) print}' > $DOCPATH/hit_mon2.log

else
        nice -n 19 awk '{print $1" "$4" "$7" "$10" "$11}' $LOG | awk -F '[' '{if (($2>="'$DAY2'/'$MONTHR2'/'$YEAR2':'$HOUR2':'$MIN2':'$SEC2'")&&($2<="'$DAY'/'$MONTHR'/'$YEAR':'$HOUR':'$MIN':'$SEC'")) print}' > $DOCPATH/hit_mon2.log
fi
}

apihit (){
#ACC=$(wc -l $DOCPATH/hit_mon2.log | cut -d " " -f 1)
ACC=$(grep -c -e "/apis" -e "/crm" $DOCPATH/hit_mon2.log)
echo "[$DATE] total API hits: $ACC" >> $DOCPATH/hit_mon.log

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_API' '' 'Total' $ACC > /dev/null 2>&1
fi

if [ $ACC -gt $LIMIT ]
then
#       cut -d " " -f 3 $DOCPATH/hit_mon2.log | sort | uniq -c | sort -n | tail -n 3 >> $DOCPATH/hit_mon.log
#       grep useAPI $DOCPATH/hit_mon2.log | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 3 >> $DOCPATH/hit_mon.log
#       echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of total API hits over the last $INT min. is $ACC." >> $DOCPATH/hit_mon.log
#       notifym2
#       notifyline2

        if [ $(grep -e "/apis" -e "/crm" $DOCPATH/hit_mon2.log | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 3 | wc -l) -eq 1 ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of total API hits over the last $INT min. is $ACC (threshold: $LIMIT)." >> $DOCPATH/hit_mon.log
                notifym
                notifyline
                notifywechat
        else
                grep -e "/apis" -e "/crm" $DOCPATH/hit_mon2.log | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 3 >> $DOCPATH/hit_mon.log
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of total API hits over the last $INT min. is $ACC (threshold: $LIMIT)." >> $DOCPATH/hit_mon.log
                notifym2
                notifyline2
                notifywechat2
        fi
fi
}

apihit2 (){
#ACC=$(wc -l $DOCPATH/hit_mon2.log | cut -d " " -f 1)
ACC=$(grep -c $API $DOCPATH/hit_mon2.log)
echo "[$DATE] $API2 hits: $ACC" >> $DOCPATH/hit_mon.log

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_API' '' $API2 $ACC > /dev/null 2>&1
fi

if [ $ACC -gt $LIMIT ]
then
#       grep $API $DOCPATH/hit_mon2.log | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 3 >> $DOCPATH/hit_mon.log
#       echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $API hits over the last $INT min. is $ACC." >> $DOCPATH/hit_mon.log
#       notifym
#       notifyline

        if [ $(grep $API $DOCPATH/hit_mon2.log | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 3 | wc -l) -eq 1 ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $API2 hits over the last $INT min. is $ACC (threshold: $LIMIT)." >> $DOCPATH/hit_mon.log
                notifym
                notifyline
                notifywechat
        else
                grep $API $DOCPATH/hit_mon2.log | cut -d " " -f 1 | sort | uniq -c | sort -n | tail -n 3 >> $DOCPATH/hit_mon.log
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $API2 hits over the last $INT min. is $ACC (threshold: $LIMIT)." >> $DOCPATH/hit_mon.log
                notifym2
                notifyline2
                notifywechat2
        fi
fi
}

slowhit (){
RESP_TIME=$(awk '{ sum += $5 } END { if (NR > 0) print sum / NR }' $DOCPATH/hit_mon2.log | awk '{printf ("%.6f\n",$1/1000000)}')
echo "[$DATE] Average time: $RESP_TIME" >> $DOCPATH/hit_mon.log

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" "HTTPD(API)" 'RESP_TIME' Average $RESP_TIME > /dev/null 2>&1
fi

COUNTER=1
while [ $COUNTER -le 5 ]
do
        eval "SLOW_API${COUNTER}=$(grep -v -e "/apis/.*/userBehavior/log" -e "/image" -e "/apis/.*/cycling " -e "/apis/.*/store" $DOCPATH/hit_mon2.log | sort -k 5 -g | tail -n ${COUNTER} | head -n 1 | cut -d " " -f 3 | cut -d "?" -f 1)"
        eval "SLOW_SIZE${COUNTER}=$(grep -v -e "/apis/.*/userBehavior/log" -e "/image" -e "/apis/.*/cycling " -e "/apis/.*/store" $DOCPATH/hit_mon2.log | sort -k 5 -g | tail -n $COUNTER | head -n 1 | cut -d " " -f 4 | numfmt --to=iec)"
        eval "SLOW_TIMEORG${COUNTER}=$(grep -v -e "/apis/.*/userBehavior/log" -e "/image" -e "/apis/.*/cycling " -e "/apis/.*/store" $DOCPATH/hit_mon2.log | sort -k 5 -g | tail -n $COUNTER | head -n 1 | cut -d " " -f 5)"
        eval "SLOW_TIME${COUNTER}=$(grep -v -e "/apis/.*/userBehavior/log" -e "/image" -e "/apis/.*/cycling " -e "/apis/.*/store" $DOCPATH/hit_mon2.log | sort -k 5 -g | tail -n $COUNTER | head -n 1 | cut -d " " -f 5 | awk '{printf ("%.6f\n",$1/1000000)}')"
        COUNTER=$(($COUNTER+1))
done

SLOW_API=($SLOW_API1 $SLOW_API2 $SLOW_API3 $SLOW_API4 $SLOW_API5)
SLOW_SIZE=($SLOW_SIZE1 $SLOW_SIZE2 $SLOW_SIZE3 $SLOW_SIZE4 $SLOW_SIZE5)
SLOW_TIMEORG=($SLOW_TIMEORG1 $SLOW_TIMEORG2 $SLOW_TIMEORG3 $SLOW_TIMEORG4 $SLOW_TIMEORG5)
SLOW_TIME=($SLOW_TIME1 $SLOW_TIME2 $SLOW_TIME3 $SLOW_TIME4 $SLOW_TIME5)

echo -e "[$DATE] slowest_hit:" >> $DOCPATH/hit_mon.log
for I in `seq 0 $(($COUNTER-2))`
do
        echo -e "${SLOW_API[$I]}-${SLOW_SIZE[$I]}:${SLOW_TIME[$I]}" >> $DOCPATH/hit_mon.log

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_SLOW' '' "${SLOW_API[$I]}-${SLOW_SIZE[$I]}" "${SLOW_TIMEORG[$I]}" > /dev/null 2>&1
        sleep 1
fi

done
}

iphit (){
echo -e "[$DATE] IP_hit:" >> $DOCPATH/hit_mon.log

#for I in $(awk '{print $1}' $DOCPATH/hit_mon2.log | grep -v -e "^127.0.0.1" | sort | uniq -c | sort -gr | sed -e 's/^ *//g' -e 's/ /,/g' | head -n 5)
for I in $(awk '{print $1}' $DOCPATH/hit_mon2.log | grep -v -e "^127.0.0.1" | sort | uniq -c | sort -gr | sed -e 's/^ *//g' -e 's/ /,/g' | head -n 6)
do
        IP=$(echo $I | cut -d "," -f 2)
        ACC=$(echo $I | cut -d "," -f 1)
        echo -e "$IP:$ACC" >> $DOCPATH/hit_mon.log

        if [ $IP != "47.100.223.127" ] && [ $IP != "139.196.31.92" ] && [ $ACC -gt $LIMIT ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $IP hits over the last $INT min. is $ACC (threshold: $LIMIT)." >> $DOCPATH/hit_mon.log
                notifym
#               notifyline
#               notifywechat
        fi

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_IP' '' "$IP" "$ACC" > /dev/null 2>&1
        fi

done
}

hitacc (){
for HIT in `cut -d " " -f 3 $DOCPATH/hit_mon2.log | cut -d "?" -f 1 | sort | uniq -c | sort -g | sed -e 's/^[ ]*//g' -e 's/ /,/g'`
do
        HIT_ACC=$(echo "$HIT" | cut -d "," -f 1)
        HIT_API=$(echo "$HIT" | cut -d "," -f 2)

        if [ $todocker_switch -eq 1 ]
        then
        bash $DOCPATH/data_mon.sh 'data_test' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_API' '' $HIT_API $HIT_ACC > /dev/null 2>&1
        fi

done
}

php_mon (){
COUNTER=1
while [ $COUNTER -le 3 ]
do
        RESP_API=$(curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "$POST" "$HOST/$API" -f)
        RESP_API2=$(echo $RESP_API | grep "total" | wc -l)

        if [ $RESP_API2 == 1 ]
        then
                ACC=$(echo $RESP_API | grep "total" | awk -F 'active processes: '  '{print $2}' | awk '{print $1}')
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] $API processes: $ACC" >> $DOCPATH/hit_mon.log

                if [ $todocker_switch -eq 1 ]
                then
                        bash $DOCPATH/data_mon.sh 'data' "$SYSTEM2" "$IP2" "$SYSTEM2" "$IP2" 'HIT_API' '' $API $ACC > /dev/null 2>&1
                fi

                if [ $ACC -gt $LIMIT ]
                then
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $API processes is $ACC (threshold: $LIMIT)." >> $DOCPATH/hit_mon.log
                        notifym
                        notifyline
                        notifywechat

#                       curl -sLk -w "\n" 'https://app.giant.com.cn/fpm-status?full' >> $DOCPATH/hit_mon.log
                fi

                break
        else
                COUNTER=$(($COUNTER+1))
                if [ $COUNTER -le 3 ]
                then
                        sleep $RETRYINT
                fi
        fi
done

if [ $COUNTER -gt 3 ] && [ $RESP_API2 != 1 ]
then
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] === Connecting to API \"$HOST/$API\" may not work properly." >> $DOCPATH/hit_mon.log
        notifym
#       notifyline
#       notifywechat
fi
}

SUBJECT="$SYSTEM monitor service alert"
YMD=$(date +%s)
INT=3600
RUNNING=10
if [ `tail -n $RUNNING $DOCPATH/hit_mon.log | grep "monitor is still running" | wc -l` -eq $RUNNING ]
then
        U=$(date +%s --date="`tail -n $RUNNING $DOCPATH/hit_mon.log | head -n 1 | cut -d "]" -f 1 | cut -d "[" -f 2`")
        if [ $(( $YMD - $U )) -le $INT ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] === hit_mon may not work properly. >> $DOCPATH/hit_mon.log
                notifym
                notifyline
                notifywechat
        fi
fi

#PS=$(ps -ef | grep hit_mon.sh | grep -c -v grep)
#echo "PS: $PS" >> $DOCPATH/hit_mon.log
#if [ $PS -gt 4 ]
if [ $(ps -ef | grep hit_mon.sh | grep -c -v grep ) -le 3 ]
then
        rm -rf $DOCPATH/hit_mon.lck > /dev/null 2>&1
fi

if [ -f $DOCPATH/hit_mon.lck ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] === monitor is still running, so exit. $PS >> $DOCPATH/hit_mon.log
        exit 0
fi

touch $DOCPATH/hit_mon.lck
todocker_switch=1

#INT=30
INT=10
INT2=$(($INT * 60))
HTTPD_BIN=/usr/sbin/apache2

DATE=$(date "+%Y-%m-%d %H:%M:%S")
DATE_U=$(date +%s -d "$DATE")
YEAR=$(echo $DATE | cut -d "-" -f 1)
MONTH=$(echo $DATE | cut -d "-" -f 2)
MONTHR=$(date -R -d "$DATE" | cut -d " " -f 3)
DAY=$(echo $DATE | cut -d "-" -f 3 | cut -d " " -f 1)
HOUR=$(echo $DATE | cut -d " " -f 2 | cut -d ":" -f 1)
MIN=$(echo $DATE | cut -d " " -f 2 | cut -d ":" -f 2)
SEC=$(echo $DATE | cut -d " " -f 2 | cut -d ":" -f 3)

DATE_U2=$(($DATE_U - $INT2))
DATE2=$(date -d @$DATE_U2 "+%Y-%m-%d %H:%M:%S")
YEAR2=$(echo $DATE2 | cut -d "-" -f 1)
MONTH2=$(echo $DATE2 | cut -d "-" -f 2)
MONTHR2=$(date -R -d "$DATE2" | cut -d " " -f 3)
DAY2=$(echo $DATE2 | cut -d "-" -f 3 | cut -d " " -f 1)
HOUR2=$(echo $DATE2 | cut -d " " -f 2 | cut -d ":" -f 1)
MIN2=$(echo $DATE2 | cut -d " " -f 2 | cut -d ":" -f 2)
SEC2=$(echo $DATE2 | cut -d " " -f 2 | cut -d ":" -f 3)

SUBJECT="$SYSTEM API total hits exceed limit."
#LIMIT=20000
LIMIT=50000
hit_mon
apihit

SUBJECT="$SYSTEM API \"/cycling\" hits exceed limit."
API="/apis/.*/cycling "
API2="/cycling"
#LIMIT=3700
LIMIT=10000
apihit2

SUBJECT="$SYSTEM API \"/userBehavior/log\" hits exceed limit."
API="/apis/.*/userBehavior/log"
API2="/userBehavior/log"
#LIMIT=2300
LIMIT=6000
apihit2

SUBJECT="$SYSTEM API \"/user/profile/info/\" hits exceed limit."
API="/apis/.*/user/profile/info/"
API2="/user/profile/info"
#LIMIT=1200
LIMIT=4000
apihit2

SUBJECT="$SYSTEM API \"/rank\" hits exceed limit."
API="/apis/.*/rank "
API2="/rank"
LIMIT=400
apihit2

SUBJECT="$SYSTEM API \"/participants\" hits exceed limit."
API="/apis/.*/activities/.*/participants"
API2="/participants"
LIMIT=100
apihit2

SUBJECT="$SYSTEM API \"/pushNotification\" hits exceed limit."
API="/apis/.*/pushNotification "
API2="/pushNotification"
LIMIT=10000
apihit2

SUBJECT="$SYSTEM API \"/tracks\" hits exceed limit."
API="/apis/.*/tracks"
API2="/tracks"
LIMIT=50
apihit2

SUBJECT="$SYSTEM API \"/routebooks\" hits exceed limit."
API="/apis/.*/routebooks"
API2="/routebooks"
#LIMIT=100
LIMIT=400
apihit2

SUBJECT="$SYSTEM API \"/medals/statistics\" hits exceed limit."
API="/apis/.*/medals/statistics"
API2="/medals/statistics"
LIMIT=2500
apihit2

HOST=http://app.giant.com.cn
SUBJECT="$SYSTEM API \"fpm-status\" processes exceed limit."
API="fpm-status"
POST=""
TIMEOUT=5
RETRYINT=3
LIMIT=100
#php_mon

SUBJECT="$SYSTEM slowest API."
slowhit

SUBJECT="$SYSTEM IP hits exceed limit."
LIMIT=1000
iphit

SUBJECT="$SYSTEM account of each API hit."
#hitacc

rm -rf $DOCPATH/hit_mon.lck > /dev/null 2>&1
#rm -rf $DOCPATH/hit_mon2.log > /dev/null 2>&1
