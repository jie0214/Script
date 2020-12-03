#!/bin/bash
DOCPATH=/home/mp_abins
MAIL=abins@program.com.tw,mis@program.com.tw,angel@program.com.tw,rosong@program.com.tw,wang@program.com.tw

#system name
#SYSTEM="CN-WEB_$(grep address /etc/network/interfaces | awk '{print $2}' | head -n 1)"
SYSTEM="GC-APP_$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"

SRC_NAME="GC-APP"
SRC_IP="$(/sbin/ifconfig | grep -A 1 eth0 | grep inet | awk '{print $2}' | cut -d ":" -f 2)"
DEST_NAME="GC-APP"

notifym (){
        tail -n 1 $DOCPATH/httpd_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' $SRC_NAME $SRC_IP $DEST_NAME $SRC_IP 'EVENT' 'HTTPD_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifym2 (){
        tail -n 5 $DOCPATH/httpd_mon.log | mail -s "$SUBJECT" -r "monitor<monitor@program.com.tw>" "$MAIL"

        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'alert' $SRC_NAME $SRC_IP $DEST_NAME $SRC_IP 'EVENT' 'HTTPD_MON' "$SUBJECT" 1 > /dev/null 2>&1
        fi
}

notifyslack(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/httpd_mon.log)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyslack2(){
        curl -s -H 'Content-type: application/json' -d "{\"text\": \"$(tail -n 1 $DOCPATH/httpd_mon.log) TOP 3:\n$(tail -n 2 $DOCPATH/httpd_mon.log | head -n 1)\n$(tail -n 3 $DOCPATH/httpd_mon.log | head -n 1)\n$(tail -n 4 $DOCPATH/httpd_mon.log | head -n 1)\", \"channel\": \"cacti-alert\", \"username\": \"$SUBJECT\", \"icon_emoji\": \":warning:\"}" https://hooks.slack.com/services/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
}

notifyline(){
        #https://notify-bot.line.me/oauth/authorize?response_type=code&client_id=EvH9H06eLVxIUfZlVobZgo&redirect_uri=http://www.google.com.tw&scope=notify&state=NO_STATE
        #curl -X POST -sLk -d "&grant_type=authorization_code&code=$1&redirect_uri=http://www.google.com.tw&client_id=EvH9H06eLVxIUfZlVobZgo&client_secret=9zk3GjwgsFfqsKSEArP8t82lXLJ35OqX0oezL4FBdyo" https://203.104.138.172/oauth/token -w "\n" | cut -d "," -f 3 | sed -e 's/"//g' -e 's/}//g'
        for LINETOKEN in `grep "^LINE:" $DOCPATH/httpd_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/httpd_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/httpd_mon.log | head -n 1)" -F "stickerPackageId=1" -F "stickerId=115" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/httpd_mon.log
                        fi
                done
        done
}

notifyline2(){
        for LINETOKEN in `grep "^LINE:" $DOCPATH/httpd_mon.txt | sed -e 's/LINE://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
#                       LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$SUBJECT $(tail -n $COUNTER $DOCPATH/httpd_mon.log | head -n 1) $(tail -n $(($COUNTER+4)) $DOCPATH/httpd_mon.log | head -n 1), $(tail -n $(($COUNTER+3)) $DOCPATH/httpd_mon.log | head -n 1), $(tail -n $(($COUNTER+2)) $DOCPATH/httpd_mon.log | head -n 1), $(tail -n $(($COUNTER+1)) $DOCPATH/httpd_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        LINERESP=$(curl -X POST -sLk --connect-timeout 5 -H "Authorization: Bearer $LINETOKEN" -F "message=$(echo $SUBJECT ; tail -n 1 $DOCPATH/httpd_mon.log | head -n 1 ; tail -n 5 $DOCPATH/httpd_mon.log | head -n 1 ; tail -n 4 $DOCPATH/httpd_mon.log | head -n 1 ; tail -n 3 $DOCPATH/httpd_mon.log | head -n 1 ; tail -n 2 $DOCPATH/httpd_mon.log | head -n 1)" https://203.104.138.174/api/notify -w "\n")
                        echo $LINERESP | grep "ok"
                        if [ $? -eq 0 ]
                        then
                                break
#                       else
#                               echo "$LINETOKEN $LINERESP retry=$COUNTER" >> $DOCPATH/httpd_mon.log
                        fi
                done
        done
}

notifywechat (){
        TOKEN=$(curl -sLk -w "\n" 'https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=wxf6a24c14959b180e&corpsecret=jvRbLWL5PMVNLcCyhaYNeNG3Tbyil1am80lSQnv0ZIU' | awk -F "," '{print $3}' | cut -d ":" -f 2 | sed 's/"//g')
        for WECHAT in `grep "^WECHAT:" $DOCPATH/httpd_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
        do
                COUNTER=1
                while [ $COUNTER -le 3 ]
                do
                        COUNTER=$(($COUNTER+1))
                        WECHATRESP=$(curl -sLk -w "\n" -d '{"touser":"'"$WECHAT"'","msgtype":"text","agentid":1000002,"text":{"content":"'"$(echo $SUBJECT | sed 's/"/\\"/g' ; tail -n 1 $DOCPATH/httpd_mon.log | head -n 1 | sed 's/"/\\"/g')"'"},"safe":0}' 'https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token='$TOKEN'')
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
        for WECHAT in `grep "^WECHAT:" $DOCPATH/httpd_mon.txt | sed -e 's/WECHAT://g' -e 's/#.*//g'`
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
                        fi
                done
        done
}

httpd_restart (){
        $HTTPD stop;
        sleep 2;
        pkill -9 $HTTPD_BIN;
        sleep 2;
        $HTTPD start

}

statuslog (){
        echo CPU loading is `cut -d " " -f 2 /proc/loadavg` >> $DOCPATH/httpd_mon.log
        echo "Account of HTTPD is `ps -ef | grep $HTTPD_BIN | grep -v grep | wc -l`" >> $DOCPATH/httpd_mon.log
        echo "Account of network connections is `netstat -nut | wc -l`" >> $DOCPATH/httpd_mon.log
        echo "Network traffic: `ifstat -T 5 1 | tail -n 1 | awk '{print "in:"$3" ""out:"$4}'`" >> $DOCPATH/httpd_mon.log
}

httpd_mon (){
COUNTER=1
while [ $COUNTER -le 3 ]
do
#       RESP_CODE=`curl -sLk -w "%{http_code}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "sid=$SID&$POST" "$HOST/$API" -o /dev/null -f`
        RESP_API=`curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT "$HOST/$API" -o /dev/null -f`
        RESP_CODE=$(echo $RESP_API | awk -F "code=" '{print $2}' | cut -d "," -f 1)
        RESP_TIME=$(echo $RESP_API | awk -F "time=" '{print $2}' | cut -d "}" -f 1)
        if [ $RESP_CODE == 200 ]
        then
                resp_mon
                break
        else
                resp_mon
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST httpd RESPONSE $COUNTER: $RESP_API. Exit code: $?" >> $DOCPATH/httpd_mon.log
                COUNTER=$(($COUNTER+1))
                if [ $COUNTER -le 3 ]
                then
                        sleep $RETRYINT
                fi
        fi
done

if [ $COUNTER -gt 3 ] && [ $RESP_CODE != 200 ] && [ $RESTART == 1 ]
then
        statuslog
        httpd_restart
#       RESP_CODE=`curl -sLk -w "%{http_code}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "sid=$SID&$POST" "$HOST/$API" -o /dev/null -f`
        RESP_API=`curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "sid=$SID&$POST" "$HOST/$API" -o /dev/null -f`
        RESP_CODE=$(echo $RESP_API | awk -F "code=" '{print $2}' | cut -d "," -f 1)
        if [ $RESP_CODE == 200 ]
        then
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] === $HOST httpd was down and restart successfully." >> $DOCPATH/httpd_mon.log
                notifym2
                notifyslack2
                notifyline2
        else
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] === $HOST httpd was down and restart failed." >> $DOCPATH/httpd_mon.log
                notifym2
                notifyslack2
                notifyline2
        fi

elif [ $COUNTER -gt 3 ] && [ $RESP_CODE != 200 ] && [ $RESTART != 1 ]
then

#for analyze
#       $DOCPATH/analyze.sh

        statuslog
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] === $HOST httpd was down." >> $DOCPATH/httpd_mon.log
        notifym2
#       notifyslack2
        notifyline2
        notifywechat2

        rm -rf $DOCPATH/httpd_mon.lck > /dev/null 2>&1
        exit 0
fi
}

monitor (){
COUNTER=1
while [ $COUNTER -le 3 ]
do
        if [ `echo $API | wc -c` -gt 1 ]
        then
#               getsid
#               RESP_API=$(curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -H "Authorization: Bearer $SID" -d "$POST" "$HOST/$API" -f)
                RESP_API=$(curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT --user "$ID:$SID" "$HOST/$API")
                RESP_API2=$(echo $RESP_API | grep "$RETCODE" | wc -l)
                RESP_CODE=$(echo $RESP_API | awk -F "code=" '{print $2}' | cut -d "," -f 1)
                RESP_TIME=$(echo $RESP_API | awk -F "time=" '{print $2}' | cut -d "}" -f 1)
        else
                RESP_API2=1
        fi

        if [ $RESP_API2 == 1 ]
        then
                resp_mon2
                break
        else
                resp_mon2
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST $API2 RESPONSE $COUNTER: $RESP_API, SID: $SID" >> $DOCPATH/httpd_mon.log
                COUNTER=$(($COUNTER+1))
                if [ $COUNTER -le 3 ]
                then
                        sleep $RETRYINT
                fi
        fi
done

#if [ $COUNTER -gt 3 ] && [ $RESP_CODE == 200 ] && [ $RESP_API2 != 1 ]
if [ $COUNTER -gt 3 ] && [ $RESP_API2 != 1 ]
then
        statuslog
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] === Connecting to API \"$HOST/$API\" may not work properly." >> $DOCPATH/httpd_mon.log
        notifym2
#       notifyslack2
        notifyline2
        notifywechat2
fi
}

getsid (){
COUNTER=1
while [ $COUNTER -le 3 ]
do
        if [ `echo $API | wc -c` -gt 1 ]
        then
                RESP_API=$(curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "$POST" "$HOST/$API" -f)
                RESP_API2=$(echo $RESP_API | grep "$RETCODE" | wc -l)
                RESP_CODE=$(echo $RESP_API | awk -F "code=" '{print $2}' | cut -d "," -f 1)
                RESP_TIME=$(echo $RESP_API | awk -F "time=" '{print $2}' | cut -d "}" -f 1)
        else
                RESP_API2=1
        fi

        if [ $RESP_API2 == 1 ]
        then
                ID=$(echo $RESP_API | awk -F '_id":"' '{print $2}' | cut -d '"' -f 1)
                SID=$(echo $RESP_API | awk -F 'access_token":"' '{print $2}' | cut -d '"' -f 1)
                resp_mon2
                break
        else
                resp_mon2
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST $API2 RESPONSE $COUNTER: $RESP_API, SID: $SID" >> $DOCPATH/httpd_mon.log
                COUNTER=$(($COUNTER+1))
                if [ $COUNTER -le 3 ]
                then
                        sleep $RETRYINT
                fi
        fi
done

if [ $COUNTER -gt 3 ] && [ $RESP_API2 != 1 ]
then
        statuslog
        echo "[`date "+%Y/%m/%d %H:%M:%S"`] === Connecting to API \"$HOST/$API\" may not work properly." >> $DOCPATH/httpd_mon.log
        notifym2
#       notifyslack2
        notifyline2
        notifywechat2

        rm -rf $DOCPATH/httpd_mon.lck > /dev/null 2>&1
        exit 0
fi
}

php_mon (){
COUNTER2=1
while [ $COUNTER2 -le 1 ]
do
        RESP_API=$(curl -sLk -w "{code=%{http_code},time=%{time_total}}\n" --connect-timeout $TIMEOUT -m $TIMEOUT -d "$POST" "$HOST/$API" -f)
        RESP_API2=$(echo $RESP_API | grep "$RETCODE" | wc -l)
        RESP_CODE=$(echo $RESP_API | awk -F "code=" '{print $2}' | cut -d "," -f 1)
        RESP_TIME=$(echo $RESP_API | awk -F "time=" '{print $2}' | cut -d "}" -f 1)

        if [ $RESP_API2 == 1 ]
        then
                ACC=$(echo $RESP_API | awk -F 'active processes: ' '{print $2}' | awk '{print $1}')
                ACC2=$(echo $RESP_API | awk -F 'total processes: ' '{print $2}' | awk '{print $1}')
                ACC3=$(echo $RESP_API | awk -F 'max children reached: ' '{print $2}' | awk '{print $1}')
#               echo "[`date "+%Y/%m/%d %H:%M:%S"`] $API processes: $ACC" >> $DOCPATH/php_mon.log

                if [ $todocker_switch -eq 1 ]
                then
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  "HTTPD(API)" 'RESP_STATUS' $API $RESP_CODE > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  "HTTPD(API)" 'RESP_TIME' $API $RESP_TIME > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  "HTTPD(API)" 'RESP_CODE' $API $RESP_API2 > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  'HIT_API' '' ${API}_active $ACC > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  'HIT_API' '' ${API}_total $ACC2 > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  'HIT_API' '' ${API}_max_reached $ACC3 > /dev/null 2>&1
                fi

                if [ $ACC -gt $LIMIT ]
                then
                        echo [`date "+%Y/%m/%d %H:%M:%S"`] "=== Account of $API processes is $ACC (threshold: $LIMIT)." >> $DOCPATH/httpd_mon.log
#                       notifym
#                       notifyline
#                       notifywechat
                fi

                COUNTER2=$(($COUNTER2+1))
                if [ $COUNTER2 -le 2 ]
                then
                        sleep $RETRYINT
                fi

        else
                echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST $API RESPONSE: $RESP_API" >> $DOCPATH/httpd_mon.log
#               echo "[`date "+%Y/%m/%d %H:%M:%S"`] === Connecting to API \"$HOST/$API\" may not work properly." >> $DOCPATH/httpd_mon.log
                notifym
#               notifyline
#               notifywechat

                if [ $todocker_switch -eq 1 ]
                then
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  "HTTPD(API)" 'RESP_STATUS' $API $RESP_CODE > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  "HTTPD(API)" 'RESP_TIME' $API $RESP_TIME > /dev/null 2>&1
                        bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1)  "HTTPD(API)" 'RESP_CODE' $API $RESP_API2 > /dev/null 2>&1
                fi

                COUNTER2=$(($COUNTER2+1))
                if [ $COUNTER2 -le 2 ]
                then
                        sleep $RETRYINT
                fi

#               break

        fi
done
}

resp_mon (){
#       echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST httpd RESP_CODE: $RESP_CODE, RESP_TIME: $RESP_TIME" >> $DOCPATH/httpd_mon.log
        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) $TYPE 'RESP_STATUS' $DEST_NAME $RESP_CODE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) $TYPE 'RESP_TIME' $DEST_NAME $RESP_TIME > /dev/null 2>&1
        fi
}

resp_mon2 (){
#       echo "[`date "+%Y/%m/%d %H:%M:%S"`] $HOST $API2 RESP_CODE: $RESP_CODE, RESP_TIME: $RESP_TIME, RESP_API2: $RESP_API2" >> $DOCPATH/httpd_mon.log
        if [ $todocker_switch -eq 1 ]
        then
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) "$TYPE(API)" 'RESP_STATUS' $API2 $RESP_CODE > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) "$TYPE(API)" 'RESP_TIME' $API2 $RESP_TIME > /dev/null 2>&1
                bash $DOCPATH/data_mon.sh 'data' $SRC_NAME $SRC_IP $DEST_NAME $(echo $HOST | cut -d "/" -f 3 | cut -d ":" -f 1) "$TYPE(API)" 'RESP_CODE' $API2 $RESP_API2 > /dev/null 2>&1
        fi
}

SUBJECT="$SYSTEM monitor service alert"
YMD=$(date +%s)
INT=600
RUNNING=10
if [ `tail -n $RUNNING $DOCPATH/httpd_mon.log | grep "monitor is still running" | wc -l` -eq $RUNNING ]
then
        U=$(date +%s --date="`tail -n $RUNNING $DOCPATH/httpd_mon.log | head -n 1 | cut -d "]" -f 1 | cut -d "[" -f 2`")
        if [ $(( $YMD - $U )) -le $INT ]
        then
                echo [`date "+%Y/%m/%d %H:%M:%S"`] === httpd_mon may not work properly. >> $DOCPATH/httpd_mon.log
                notifym
                notifyline
                notifywechat
        fi
fi

#PS=$(ps -ef | grep httpd_mon.sh | grep -c -v grep)
#if [ $PS -gt 5 ]
if [ $(ps -ef | grep httpd_mon.sh | grep -c -v grep ) -le 3 ]
then
        rm -rf $DOCPATH/httpd_mon.lck > /dev/null 2>&1
fi

if [ -f $DOCPATH/httpd_mon.lck ]
then
        echo [`date "+%Y/%m/%d %H:%M:%S"`] === monitor is still running, so exit. $PS >> $DOCPATH/httpd_mon.log
        exit 0
fi

touch $DOCPATH/httpd_mon.lck
todocker_switch=1

HTTPD=/usr/sbin/apache2ctl
HTTPD_BIN=/usr/sbin/apache2
RESTART=0

HOST=http://app.giant.com.cn
#SUBJECT="$SYSTEM API \"fpm-status\" processes exceed limit."
SUBJECT="$SYSTEM \"fpm-status\" API alert."
API="fpm-status"
POST=""
RETCODE="total"
TIMEOUT=5
RETRYINT=0
LIMIT=100
php_mon &

HOST=https://app.giant.com.cn
SUBJECT="$SYSTEM HTTPD service alert."
TYPE="HTTPD"
API=""
API2=""
POST=""
RETCODE=""
TIMEOUT=10
RETRYINT=3
httpd_mon

HOST=https://app.giant.com.cn
SUBJECT="$SYSTEM 「登入」 API alert."
TYPE="HTTPD"
API="apis/v1/user/profile/login"
API2="登入"
POST="account=13120191101&password=rltest&device_os=android&device_os_version=8.0&model=test&app_version=2.0.1"
RETCODE='success":true'
TIMEOUT=10
RETRYINT=5
getsid

HOST=https://app.giant.com.cn
SUBJECT="$SYSTEM 「UserProfile-目標」 API alert."
TYPE="HTTPD"
API="apis/v1/user/profile/target"
API2="UserProfile-目標"
POST=""
RETCODE='success":true'
TIMEOUT=10
RETRYINT=5
monitor

HOST=https://app.giant.com.cn
SUBJECT="$SYSTEM 「徽章統計」 API alert."
TYPE="HTTPD"
API="apis/v1.1/user/medals/statistics"
API2="medals-statistics"
POST=""
RETCODE='success":true'
TIMEOUT=10
RETRYINT=5
monitor

HOST=https://app.giant.com.cn
SUBJECT="$SYSTEM 「門店列表」 API alert."
TYPE="HTTPD"
API="apis/v2/store"
API2="門店列表"
POST=""
RETCODE='success":true'
TIMEOUT=10
RETRYINT=5
#monitor

wait
rm -rf $DOCPATH/httpd_mon.lck > /dev/null 2>&1
