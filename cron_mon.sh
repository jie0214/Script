#!/bin/bash
DOCPATH=/home/mp_abins
#MAIL=abins@program.com.tw,angel@program.com.tw,rosong@program.com.tw
MAIL=abins@program.com.tw

SYSTEM="GC-APP_$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"
SYSTEM2="GC-APP"
SRC_IP="$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"

notifym (){
        tail -n 1 $DOCPATH/cron_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' "$SYSTEM2" "$SRC_IP" "$SYSTEM2" "$SRC_IP" 'EVENT' 'CRON_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifym2 (){
        tail -n 5 $DOCPATH/cron_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' "$SYSTEM2" "$SRC_IP" "$SYSTEM2" "$SRC_IP" 'EVENT' 'CRON_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifyslack(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/cron_mon.log)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyslack2(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/cron_mon.log) TOP 3:\n$(tail -n 2 $DOCPATH/cron_mon.log | head -n 1)\n$(tail -n 3 $DOCPATH/cron_mon.log | head -n 1)\n$(tail -n 4 $DOCPATH/cron_mon.log | head -n 1)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyline(){
        #https://notify-bot.line.me/oauth/authorize?response_type=code&client_id=EvH9H06eLVxIUfZlVobZgo&redirect_uri=http://www.google.com.tw&scope=notify&state=NO_STATE
        #curl -X POST -sLk -d "&grant_type=authorization_code&code=$1&redirect_uri=http://www.google.com.tw&client_id=EvH9H06eLVxIUfZlVobZgo&client_secret=9zk3GjwgsFfqsKSEArP8t82lXLJ35OqX0oezL4FBdyo" https://203.104.138.172/oauth/token -w "\n" | cut -d "," -f 3 | sed -e 's/"//g' -e 's/}//g'
        for LINETOKEN in `grep "^LINE:" $DOCPATH/cron_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/cron_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/cron_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/cron_mon.log
                        fi
                done
        done
}

notifyline2(){
        for LINETOKEN in `grep "^LINE:" $DOCPATH/cron_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/cron_mon.log | head -n 1) TOP3: $(tail -n $(($COUNTER+1)) $DOCPATH/cron_mon.log | head -n 1), $(tail -n $(($COUNTER+2)) $DOCPATH/cron_mon.log | head -n 1), $(tail -n $(($COUNTER+3)) $DOCPATH/cron_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/cron_mon.log | head -n 1 ; echo TOP 3: ; tail -n 2 $DOCPATH/cron_mon.log | head -n 1 ; tail -n 3 $DOCPATH/cron_mon.log | head -n 1 ; tail -n 4 $DOCPATH/cron_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/cron_mon.log
                        fi
                done
        done
}

notifywechat (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
          for WECHAT in `grep "^WECHAT:" $DOCPATH/cron_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
          do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/cron_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
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
        for WECHAT in `grep "^WECHAT:" $DOCPATH/cron_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/cron_mon.log | head -n 1 | sed 's/"/\\"/g' ; echo TOP 3: ; echo $(tail -n 2 $DOCPATH/cron_mon.log | head -n 1 | sed 's/"/\\"/g') ; echo $(tail -n 3 $DOCPATH/cron_mon.log | head -n 1 | sed 's/"/\\"/g') ; echo $(tail -n 4 $DOCPATH/cron_mon.log | head -n 1 | sed 's/"/\\"/g'))"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
                        echo $WECHATRESP | grep '""'
                        if [ $? -eq 0 ]
                        then
                                break
                        fi
                done
        done
}

statuslog (){
        echo CPU loading is `cut -d " " -f 2 /proc/loadavg` >> $DOCPATH/cron_mon.log
        echo "Account of HTTPD is `ps -ef | grep $HTTPD_BIN | grep -v grep | wc -l`" >> $DOCPATH/cron_mon.log
        echo "Account of network connections is `netstat -nut | wc -l`" >> $DOCPATH/cron_mon.log
        echo "Network traffic: `ifstat -T 5 1 | tail -n 1 | awk '{print "in:"$3" ""out:"$4}'`" >> $DOCPATH/cron_mon.log
}

cron_mon (){
LOG=/var/www/html/storage/logs/commands/$CRON_NAME/$DATE_YMD
LOG2=/var/www/html/storage/logs/commands/$CRON_NAME/$DATE_YMD2

if [ $(echo $DATE | cut -d " " -f 1 | sed 's/-//g') -eq $(echo $DATE2 | cut -d " " -f 1 | sed 's/-//g') ]
then
        nice -n 19 awk -F '[' '{if (($2 >= '"\"$DATE2\""')&&($2 <= '"\"$DATE\""')) print}' $LOG > $DOCPATH/cron_mon2.log

else
        nice -n 19 awk -F '[' '{if (($2 >= '"\"$DATE2\""')&&($2 <= '"\"$DATE\""')) print}' $LOG2 $LOG > $DOCPATH/cron_mon2.log
fi

COUNT=$(grep -c "$START" $DOCPATH/cron_mon2.log)
echo [`date "+%Y/%m/%d %H:%M:%S"`] "${CRON_NAME2}_times: $COUNT" >> $DOCPATH/cron_mon.log

#if [ $COUNT -eq 0 ]
if [ $COUNT -lt $LIMIT ]
then
#       echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== $CRON_NAME may not work properly." >> $DOCPATH/cron_mon.log
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $CRON_NAME hits over the last $INT min. is $COUNT (threshold: $LIMIT)." >> $DOCPATH/cron_mon.log
        notifym
#       notifysms
#       notifyslack
#       notifyline
#       notifywechat
fi

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data_test' $SYSTEM2 $SRC_IP $SYSTEM2 $SRC_IP "CRON" "$INTERVAL" "${CRON_NAME2}_times" $COUNT > /dev/null 2>&1
fi
}

cron_mon2 (){
LOG=/var/www/html/storage/logs/commands/$CRON_NAME/$DATE_YMD
LOG2=/var/www/html/storage/logs/commands/$CRON_NAME/$DATE_YMD2

rm -f $DOCPATH/${CRON_NAME2}_${DATE_YMD3}.log 2>/dev/null

DATE_CRON="$(date "+%Y-%m-$CRON_TIME")"
#DATE_CRONU=$(($(date +%s -d "$DATE_CRON") + 60))
DATE_CRONU=$(date +%s -d "$DATE_CRON")
DATE_CRON2=$(date "+%Y-%m-$CRON_TIME" -d @$(($DATE_U - 86400)))

#if [ $DATE_U -ge $DATE_CRONU ]
if [ $DATE_U -gt $DATE_CRONU ]
then
#       nice -n 19 awk -F '[' -v var="$DATE_CRON2" '{$1 = var; if ($2 >= $0) print}' $LOG > $DOCPATH/cron_mon2.log
        nice -n 19 awk -F '[' '{if ($2 >= '"\"$DATE_CRON\""') print}' $LOG > $DOCPATH/cron_mon2.log
        COUNT=$(grep -c "$START" $DOCPATH/cron_mon2.log)
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "${CRON_NAME2}_times: $COUNT" >> $DOCPATH/cron_mon.log

        if [ $COUNT -eq 0 ]
        then
                if [ ! -e $DOCPATH/${CRON_NAME2}_${DATE_YMD}.log ]
                then
                        touch $DOCPATH/${CRON_NAME2}_${DATE_YMD}.log
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== $CRON_NAME may not work properly." >> $DOCPATH/cron_mon.log
                        notifym
#                       notifysms
#                       notifyslack
#                       notifyline
#                       notifywechat
                fi

        else
                rm -f $DOCPATH/${CRON_NAME2}_${DATE_YMD}.log 2>/dev/null
        fi

else
#       nice -n 19 awk -F '[' '{if ($2 >= '"\"$DATE_CRON2\""') print}' $LOG2 $LOG > $DOCPATH/cron_mon2.log
        nice -n 19 awk -F '[' '{if (($2 >= '"\"$DATE_CRON2\""')&&($2 < '"\"$DATE_CRON\""'))  print}' $LOG2 $LOG > $DOCPATH/cron_mon2.log
        COUNT=$(grep -c "$START" $DOCPATH/cron_mon2.log)
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "${CRON_NAME2}_times: $COUNT" >> $DOCPATH/cron_mon.log

        if [ $COUNT -eq 0 ]
        then
                if [ ! -e $DOCPATH/${CRON_NAME2}_${DATE_YMD2}.log ]
                then
                        touch $DOCPATH/${CRON_NAME2}_${DATE_YMD2}.log
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== $CRON_NAME may not work properly." >> $DOCPATH/cron_mon.log
                        notifym
#                       notifysms
#                       notifyslack
#                       notifyline
#                       notifywechat
                fi
        else
                rm -f $DOCPATH/${CRON_NAME2}_${DATE_YMD2}.log 2>/dev/null
        fi

fi

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data_test' $SYSTEM2 $SRC_IP $SYSTEM2 $SRC_IP "CRON" "$INTERVAL" "${CRON_NAME2}_times" $COUNT > /dev/null 2>&1
fi
}

cron_mon3 (){
LOG=/var/www/html/storage/logs/commands/$CRON_NAME/$DATE_YM
LOG2=/var/www/html/storage/logs/commands/$CRON_NAME/$DATE_YM2

rm $DOCPATH/${CRON_NAME2}_${DATE_YM3}.log 2>/dev/null

DATE_CRON="$(date "+%Y-%m-$CRON_TIME")"
DATE_CRONU=$(($(date +%s -d "$DATE_CRON") + 60))
DATE_CRON2=$(date "+%Y-%m-$CRON_TIME" -d "$(date "+%Y-%m-01") -1 month")

if [ $DATE_U -ge $DATE_CRONU ]
then
        nice -n 19 awk -F '[' '{if ($2 >= '"\"$DATE_CRON\""') print}' $LOG > $DOCPATH/cron_mon2.log
        COUNT=$(grep -c "$START" $DOCPATH/cron_mon2.log)
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "${CRON_NAME2}_times: $COUNT" >> $DOCPATH/cron_mon.log

        if [ $COUNT -eq 0 ]
        then
                if [ ! -e $DOCPATH/${CRON_NAME2}_${DATE_YM}.log ]
                then
                        touch $DOCPATH/${CRON_NAME2}_${DATE_YM}.log
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== $CRON_NAME may not work properly." >> $DOCPATH/cron_mon.log
                        notifym
#                       notifysms
#                       notifyslack
#                       notifyline
#                       notifywechat
                fi
        else
                rm -f $DOCPATH/${CRON_NAME2}_${DATE_YM}.log 2>/dev/null
        fi

else
        nice -n 19 awk -F '[' '{if ($2 >= '"\"$DATE_CRON2\""') print}' $LOG2 $LOG > $DOCPATH/cron_mon2.log
        COUNT=$(grep -c "$START" $DOCPATH/cron_mon2.log)
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "${CRON_NAME2}_times: $COUNT" >> $DOCPATH/cron_mon.log

        if [ $COUNT -eq 0 ]
        then
                if [ ! -e $DOCPATH/${CRON_NAME2}_${DATE_YM2}.log ]
                then
                        touch $DOCPATH/${CRON_NAME2}_${DATE_YM2}.log
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== $CRON_NAME may not work properly." >> $DOCPATH/cron_mon.log
                        notifym
#                       notifysms
#                       notifyslack
#                       notifyline
#                       notifywechat
                fi
        else
                rm -f $DOCPATH/${CRON_NAME2}_${DATE_YM2}.log 2>/dev/null
        fi

fi

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data_test' $SYSTEM2 $SRC_IP $SYSTEM2 $SRC_IP "CRON" "$INTERVAL" "${CRON_NAME2}_times" $COUNT > /dev/null 2>&1
fi
}


cron_mon4 (){
COUNT=$(nice -n 19 awk -F '[' '{if (($2 >= '"\"$DATE2\""')&&($2 <= '"\"$DATE\""')) print}' $DOCPATH/cron_mon2.log | grep "$END" | awk '{s+=$5} END {printf "%.0f", s}')
COUNT2=$(nice -n 19 awk -F '[' '{if (($2 >= '"\"$DATE2\""')&&($2 <= '"\"$DATE\""')) print}' $DOCPATH/cron_mon2.log | grep "$END" | awk '{s+=$7} END {printf "%.0f", s}')

if [ -z "$COUNT" ]
then
        COUNT=0
fi

if [ -z "$COUNT2" ]
then
        COUNT2=0
fi
        echo [`date "+%Y/%m/%d %H:%M:%S"`] "${CRON_NAME2}_total: $COUNT, failed: $COUNT2." >> $DOCPATH/cron_mon.log

if [ $todocker_switch -eq 1 ]
then
        bash $DOCPATH/data_mon.sh 'data_test' $SYSTEM2 $SRC_IP $SYSTEM2 $SRC_IP "CRON" "$INTERVAL" "${CRON_NAME2}_total" $COUNT > /dev/null 2>&1
        bash $DOCPATH/data_mon.sh 'data_test' $SYSTEM2 $SRC_IP $SYSTEM2 $SRC_IP "CRON" "$INTERVAL" "${CRON_NAME2}_failed" $COUNT2 > /dev/null 2>&1
fi
}

SUBJECT="$SYSTEM monitor service alert"
YMD=$(date +%s)
INT=3600
RUNNING=10
if [ `tail -n $RUNNING $DOCPATH/cron_mon.log | grep "monitor is still running" | wc -l` -eq $RUNNING ]
then
        U=$(date +%s --date="$(tail -n $RUNNING $DOCPATH/cron_mon.log | head -n 1 | cut -d "]" -f 1 | cut -d "[" -f 2)")
        if [ $(( $YMD - $U )) -le $INT ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] === cron_mon may not work properly. >> $DOCPATH/cron_mon.log
                notifym
                notifyline
                notifywechat
        fi
fi

#PS=`ps -ef | grep cron_mon.sh | grep -v grep | wc -l`
#if [ $PS -gt 5 ]
if [ $(ps -ef | grep cron_mon.sh | grep -c -v grep ) -le 3 ]
then
        rm -rf $DOCPATH/cron_mon.lck > /dev/null 2>&1
fi

if [ -f $DOCPATH/cron_mon.lck ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] === monitor is still running, so exit. $PS >> $DOCPATH/cron_mon.log
        exit 0
fi

touch $DOCPATH/cron_mon.lck
todocker_switch=1

INT=10
DATE=$(date "+%Y-%m-%d %H:%M:00")
DATE_U=$(date +%s -d "$DATE")
DATE2=$(date "+%Y-%m-%d %H:%M:00" -d @$(($DATE_U - $(($INT * 60)))))
DATE_YMD=$(date "+%Y%m%d" -d "$DATE")
DATE_YMD2=$(date "+%Y%m%d" -d @$(($DATE_U - 86400)))
DATE_YMD3=$(date "+%Y%m%d" -d @$(($DATE_U - 86400 * 2)))
DATE_YM=$(date "+%Y%m" -d "$(date "+%Y-%m-01")")
DATE_YM2=$(date "+%Y%m" -d "$(date "+%Y-%m-01") -1 month")
DATE_YM3=$(date "+%Y%m" -d "$(date "+%Y/%m/01") -2 month")

SUBJECT="$SYSTEM \"appendToParticipants\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="medal/appendToParticipants"
CRON_NAME2="min_appendToParticipants"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=5
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"appendToUsers\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="medal/appendToUsers"
CRON_NAME2="min_appendToUsers"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=5
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"dline:sync\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="dline/SendCyclingDataToDLine"
CRON_NAME2="min_dline_sync"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=0
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"Notification:push\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="notification/PushNotification"
CRON_NAME2="min_Notification_push"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=0
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"cycling:toBaiduStatic\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="cycling/toBaiduStaticImage"
CRON_NAME2="min_cycling_toBaiduStatic"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=0
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"routebook:toBaiduStaticImage\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="routebook/toBaiduStaticImage"
CRON_NAME2="min_routebook_toBaiduStaticImage"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=0
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"routebook:adjust_altitude\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="routebook/adjust_altitude"
CRON_NAME2="min_routebook_adjust_altitude"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=0
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"dline:pointRecord\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="points/SendPointRecordToDLine"
CRON_NAME2="min_dline_pointRecord"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=0
cron_mon
cron_mon4

SUBJECT="$SYSTEM \"cycling:continue\" crontab alert."
INTERVAL="MINUTE"
CRON_NAME="cycling/ContinueCycling"
CRON_NAME2="min_cycling_continue"
CRON_TIME="%d %H:%M:00"
START=" start"
END=" end"
LIMIT=5
#cron_mon
#cron_mon4

SUBJECT="$SYSTEM \"dline:syncUserFirstLoginTime\" crontab alert."
INTERVAL="DAILY"
CRON_NAME="syncUserFirstLoginTimeToDline"
CRON_NAME2="daily_dline_syncUserFirstLoginTime"
CRON_TIME="%d 04:00:00"
START=" start"
END=" end"
cron_mon2
cron_mon4

SUBJECT="$SYSTEM \"update:Store\" crontab alert."
INTERVAL="DAILY"
CRON_NAME="StoreUpdate"
CRON_NAME2="daily_update_Store"
CRON_TIME="%d 03:00:00"
START=" start"
END=" end"
cron_mon2
cron_mon4

SUBJECT="$SYSTEM \"oss:LogsUpdate\" crontab alert."
INTERVAL="DAILY"
CRON_NAME="ossLogsUpdate"
CRON_NAME2="daily_oss_LogsUpdate"
CRON_TIME="%d 02:00:00"
START=" start"
END=" end"
cron_mon2
cron_mon4

SUBJECT="$SYSTEM \"fitRecord:delete\" crontab alert."
INTERVAL="DAILY"
CRON_NAME="cycling/DeleteFitRecordOverdue"
CRON_NAME2="daily_fitRecord_delete"
CRON_TIME="%d 01:00:00"
START=" start"
END=" end"
cron_mon2
cron_mon4

SUBJECT="$SYSTEM \"cycling:DeleteOlderFiles\" crontab alert."
INTERVAL="DAILY"
CRON_NAME="cycling/DeleteOlderFiles"
CRON_NAME2="daily_cycling_DeleteOlderFiles"
CRON_TIME="%d 23:00:00"
START=" start"
END=" end"
cron_mon2
cron_mon4

SUBJECT="$SYSTEM \"UserInfo:get\" crontab alert."
INTERVAL="MONTHLY"
CRON_NAME="report/UserInfo"
CRON_NAME2="mon_UserInfo"
CRON_TIME="01 00:20:00"
START=" start"
END=" end"
cron_mon3
cron_mon4

rm -rf $DOCPATH/cron_mon.lck > /dev/null 2>&1
#rm -rf $DOCPATH/cron_mon2.log > /dev/null 2>&1
