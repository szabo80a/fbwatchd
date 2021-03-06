#!/bin/bash

#####
# checks the sip status on fritz.box and reboot it by failure
# szabo80a 
#####

CONFIGFILE="/etc/fbwatchd.cfg"

source $CONFIGFILE

STATE_FILE="/tmp/fbwatchd/fon_status"
LOGFILE="/tmp/fbwatchd/fbwatchd.log"
touch $LOGFILE


function sip_status {
    IP=$1
    USER=$2
    PW=$3
    BOXURL="http://${IP}"
    REQUESTPAGE="/query.lua?fon=sip:settings/sip/list(connect)"

    ### LOGIN via login_sid.lua

    CHALLENGE=$(curl -s "${BOXURL}/login_sid.lua?username=${USER}" | grep -Po '(?<=<Challenge>).*(?=</Challenge>)')
    MD5=$(echo -n ${CHALLENGE}"-"${PW} | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b | awk '{print substr($0,1,32)}')
    RESPONSE="${CHALLENGE}-${MD5}"
    SID=$(curl -i -s -k -d "response=${RESPONSE}&username=${USER}" "${BOXURL}" | grep -Po -m 1 '(?<=sid=)[a-f\d]+')

    ###check first fon is active via query.lua
    STATUS=$(curl -s "${BOXURL}${REQUESTPAGE}" -d "sid=${SID}" | jq '.fon[0].connect '| sed 's/"//g')
    
    echo $STATUS
    }


function fb_reboot {
    IP=$1
    USER=$2
    PW=$3

    location="/upnp/control/deviceconfig"
    uri="urn:dslforum-org:service:DeviceConfig:1"
    action='Reboot'

    #### REBOOT via upnp
    curl -k -m 5 --anyauth -u "$USER:$PW" http://$IP:49000$location -H 'Content-Type: text/xml; charset="utf-8"' -H "SoapAction:$uri#$action" -d "<?xml version='1.0' encoding='utf-8'?><s:Envelope s:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/' xmlns:s='http://schemas.xmlsoap.org/soap/envelope/'><s:Body><u:$action xmlns:u='$uri'></u:$action></s:Body></s:Envelope>" -s >/dev/null
    return
    }


function sip_state_2_text {
   # connect = 0 => sip nicht activated und (somit) nicht registriert
   # connect = 1 => sip activated aber nicht registriert
   # connect = 2 => sip activated und registriert
   STATE=$1

   if [[ "STATE" -eq "0" ]]; then 
     text="0: sip not activated"
   elif [[ "STATE" -eq "1" ]]; then 
     text="1: sip activated but not registred"
   elif [[ "STATE" -eq "2" ]]; then 
     text="2: sip activated and registred"
   else 
     text="$STATE sip call"
   fi

   echo $text
   }

## main

echo "$(date) - start watching..." >> $LOGFILE

COUNT=1
while :
do
    touch /tmp/fbwatchd/fb_watch
    SIP_STATUS=$(sip_status $FRITZIP $FRITZUSER $FRITZPW)

    if [[ "$SIP_STATUS" -eq "2" ]]; then
	    echo "OK SIP STATUS: $(sip_state_2_text $SIP_STATUS)" > $STATE_FILE 
	COUNT=1
    elif [[ "$SIP_STATUS" -eq "3" ]]; then
	    echo "OK SIP STATUS: $(sip_state_2_text $SIP_STATUS)" > $STATE_FILE
	COUNT=1
    else 
	echo "ERROR $COUNT SIP STATUS: $(sip_state_2_text $SIP_STATUS)" > $STATE_FILE
	echo "$(date) - ERROR $COUNT SIP STATUS: $(sip_state_2_text $SIP_STATUS)" >> $LOGFILE
        ((COUNT=COUNT+1))
    fi

    if [[ "$COUNT" -eq "$RETRY" ]]; then
	echo "ERROR $COUNT - SIP STATUS: $(sip_state_2_text $SIP_STATUS) - REBOOT FRITZ!BOX" > $STATE_FILE
	echo "$(date) - ERROR $COUNT - SIP STATUS: $(sip_state_2_text $SIP_STATUS) - REBOOT FRITZ!BOX" >> $LOGFILE
        fb_reboot $FRITZIP $FRITZUSER $FRITZPW
	COUNT=1
    fi

    NOW=$(date +%s)
    LF_ATIME=$(stat -c %X /tmp/fbwatchd/fb_watch)
    SLEEP=$(($INTERVAL - ($NOW - $LF_ATIME)))
    sleep $SLEEP
done	
