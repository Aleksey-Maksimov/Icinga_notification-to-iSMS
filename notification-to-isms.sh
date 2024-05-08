#!/bin/bash
#
# Script for SMS notifications for Icinga via Multi-Tech MultiModem iSMS Server
# Aleksey Maksimov <aleksey.maksimov@it-kb.ru>
#
# Tested on:
# - Debian GNU/Linux 10.9 (Buster)
# - Icinga r2.8.8
# - Multi-Tech MultiModem iSMS Server SF800-G with firmware 1.51.28
# The latest version of the iSMS firmware can be downloaded from the link: 
# ftp://ftp.multitech.com/engineering/unofficial-releases/iSMS%20(Formerly%20SMSFinder)/Firmware/
#
# In the iSMS device settings, you need to set the following parameters:
# 1) Menu "SMS Services" -> "SMS Settings" need to enable options "Enable PDU Mode" and "Concatenate Multipart Outbound Messages"
# 2) Menu "SMS Services" -> "SMS Settings" in "ASCII 7-bit Configuration" need to change option "Character Set" to "3GPP 23.038"
# 3) Menu "SMS Services" -> "SMS API" in "HTTP API Configuration" need to change option "Preferred Character Set" to "UTF-8"
#
# Put here /etc/icinga2/scripts/notification-to-isms.sh
#
# 2021.04.23 - Initial version
#
PLUGIN_NAME="Plugin for SMS notifications for Icinga via Multi-Tech MultiModem Intelligent SMS Server"
PLUGIN_VERSION="2021.04.23"
PRINTINFO=`printf "\n%s, version %s\n \n" "$PLUGIN_NAME" "$PLUGIN_VERSION"`
#
#
Usage() {
  echo "$PRINTINFO"
  echo "Usage: $0 [OPTIONS]

Option   GNU long option         Meaning
------   ---------------	 -------
 -M      --plugin-mode           Plugin mode. Static value. Possible values: host-mode|service-mode
 -a      --notification-type	 Icinga Notification type (for example, from a variable \$notification.type\$)
 -b      --notification-autor	 Icinga Notification autor (for example, from a variable \$notification.author\$)
 -c      --notification-comment  Icinga Notification comment (for example, from a variable \$notification.comment\$)
 -d      --long-datetime	 Icinga Notification date and time (for example, from a variable \$icinga.long_date_time\$)
 -e      --host-displayname	 Icinga Host name (for example, from a variable \$host.display_name\$)
 -f      --host-alias		 Icinga Host alias (for example, from a variable \$host.name\$)
 -g      --host-address		 Icinga Host address (for example, from a variable \$address\$)
 -h      --host-state		 Icinga Host last state (for example, from a variable \$host.state\$)
 -i      --host-output		 Icinga Host monitoring plugin output (for example, from a variable \$host.output\$)
 -j      --service-displayname   Icinga Service display name (for example, from a variable \$service.display_name\$)
 -k      --service-desc		 Icinga Service alias (for example, from a variable \$service.name\$)
 -l      --service-state	 Icinga Service last state (for example, from a variable \$service.state\$ )
 -m      --service-output	 Icinga Service monitoring plugin output (for example, from a variable \$service.output\$)
 -z      --item-comment          Additional item comment with custom variable from Host or Service (for example, from a variable \$host.Notification_Comment\$)
 -n      --sms-to		 Email address for "To:" header (for example, from a variable \$user.pager\$)
 -S	 --isms-server		 iSMS Server address in format "host:port"
 -U	 --isms-user		 iSMS Server user login
 -P	 --isms-password	 iSMS Server user password
 -Q	 --isms-priority	 SMS priority in iSMS queue. Possible values: 1|2|3. Default value:2. 1 - Low, 2 - Normal, 3 - High. 
 -N	 --isms-modem-num	 Number of modem in iSMS. Possible values: 0-8 (0-4 for SF400, 0-8 for SF800). 0 for any modem (Send API job is distributed using all the available modems) 
 -q      --help                  Show this message
 -v      --version		 Print version information and exit

"
}

# Parse arguments
#
if [ -z $1 ]; then
    Usage; exit 1;
fi
#
OPTS=`getopt -o M:a:b:c:d:e:f:g:h:i:j:k:l:m:z:n:S:U:P:Q:N:qv -l plugin-mode:,notification-type:,notification-autor:,notification-comment:,long-datetime:,host-displayname:,host-alias:,host-address:,host-state:,host-output:,service-displayname:,service-desc:,service-state:,service-output:,item-comment:,sms-to:,isms-server:,isms-user:,isms-password:,isms-priority:,isms-modem-num:,help,version -- "$@"`
eval set -- "$OPTS"
while true; do
        case $1 in
                -M|--plugin-mode)
      			case "$2" in
                        "host-mode"|"service-mode") PLUGINMODE=$2 ; shift 2 ;;
                                                 *) printf "Unknown value for option %s. Use 'host-mode' or 'service-mode'\n" "$1" ; exit 1 ;;
			esac ;;
                -a|--notification-type)
                        NOTIFICATIONTYPE=$2 ; shift 2 ;;
                -b|--notification-autor)
                        NOTIFICATIONAUTHORNAME=$2 ; shift 2 ;;
                -c|--notification-comment)
                        NOTIFICATIONCOMMENT=$2 ; shift 2 ;;
                -d|--long-datetime)
                        LONGDATETIME=$2 ; shift 2 ;;
                -e|--host-displayname)
                        HOSTDISPLAYNAME=$2 ; shift 2 ;;
                -f|--host-alias)
                        HOSTALIAS=$2 ; shift 2 ;;
                -g|--host-address)
                        HOSTADDRESS=$2 ; shift 2 ;;
                -h|--host-state)
                        HOSTSTATE=$2 ; shift 2 ;;
                -i|--host-output)
                        HOSTOUTPUT=$2 ; shift 2 ;;
                -j|--service-displayname)
                        SERVICEDISPLAYNAME=$2 ; shift 2 ;;
                -k|--service-desc)
                        SERVICEDESC=$2 ; shift 2 ;;
                -l|--service-state)
                        SERVICESTATE=$2 ; shift 2 ;;
                -m|--service-output)
                        SERVICEOUTPUT=$2 ; shift 2 ;;
                -z|--item-comment)
                        ITEMCOMMENT=$2 ; shift 2 ;;
                -n|--sms-to)
                        SMSTO=$2 ; shift 2 ;;
 		-S|--isms-server)
			ISMSSRV=$2 ; shift 2 ;;
 		-U|--isms-user)
			ISMSUSR=$2 ; shift 2 ;;
 		-P|--isms-password)
			ISMSPWD=$2 ; shift 2 ;;
                -Q|--isms-priority)
                        case "$2" in
                        "1"|"2"|"3") ISMSPRIO=$2 ; shift 2 ;;
                                  *) printf "Unknown value for option %s. Use integer from '1' to '3'\n" "$1" ; exit 1 ;;
                        esac ;;
                -N|--isms-modem-num)
                        case "$2" in
                        "0"|"1"|"2"|"3"|"4"|"5"|"6"|"7"|"8") ISMSMODEM=$2 ; shift 2 ;;
                                  *) printf "Unknown value for option %s. Use integer from '0' to '8'\n" "$1" ; exit 1 ;;
                        esac ;;
                -q|--help)
                        Usage ; exit 0 ;;
                -v|--version)
			echo "$PRINTINFO" ; exit 0 ;;
                --)
                        # no more arguments to parse
                        shift ; break ;;
                *)
                        printf "\nUnrecognized option %s\n\n" "$1" ; Usage ; exit 1 ;;
        esac 
done


# Set default values
#
if [ -z "$ISMSPRIO" ]; then
  ISMSPRIO="2"
fi
if [ -z "$ISMSMODEM" ]; then
  ISMSMODEM="0"
fi


# Output normalization
#
#TIMETOSMS=`echo $(date -d "$LONGDATETIME" +"%d.%m.%Y %T %Z")`
TIMETOSMS=`echo $(date -d "$LONGDATETIME" +"%d.%m.%Y %T")`
if [ -n "$ITEMCOMMENT" ]; then
  ITEMCOMMENTTOSMS=`echo Data: $ITEMCOMMENT`
fi
if [ -n "$NOTIFICATIONAUTHORNAME" ]; then 
  COMMENTTOSMS=`echo Comment: $NOTIFICATIONAUTHORNAME : $NOTIFICATIONCOMMENT`
fi
if [ -n "$SERVICEOUTPUT" ]; then
  SERVICEOUTPUTTOSMS=`echo $SERVICEOUTPUT | cut -c1-100`
fi


# SMS text generation
#
if [ "$PLUGINMODE" = "host-mode" ]; then
template=$(cat <<TEMPLATE
Icinga $NOTIFICATIONTYPE
Host: $HOSTDISPLAYNAME ($HOSTADDRESS)
Info: $HOSTOUTPUT
Time: $TIMETOSMS
$ITEMCOMMENTTOSMS
$COMMENTTOSMS
TEMPLATE
)
elif [ "$PLUGINMODE" = "service-mode" ]; then
template=$(cat <<TEMPLATE
Icinga $NOTIFICATIONTYPE
Host: $HOSTDISPLAYNAME
Service: $SERVICEDESC
State: $SERVICEOUTPUTTOSMS
Time: $TIMETOSMS
$ITEMCOMMENTTOSMS
$COMMENTTOSMS
TEMPLATE
)
fi

# Function for convering ASCII string to URL encoding
# https://gist.github.com/cdown/1163649
#
ASCIIStrToURL() {
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    LC_COLLATE=$old_lc_collate
}

# Function for convering string to hexadecimal form
# https://stackoverflow.com/a/48685401/4127960
# fmt="0x%x" returns like "0x410x420x43"
# fmt="%x;"  returns like "41;42;43;"
#
StrToHex() {
  local str=${1:-""}
  local fmt="%x;"
  local chr
  local -i i
  for i in `seq 0 $((${#str}-1))`; do
    chr=${str:i:1}
    printf  "${fmt}" "'${chr}"
  done
}


# Data normalization for iSMS
#
# Check is body in English and convert to Hex
#
if ! echo -n "$template" | iconv -t ISO-8859-15 > /dev/null 2>&1; then
  # Text isn't in English. Set SMS text in Hexadecimal form 
  ISMSENC="2"
  ISMSTEXT=$( StrToHex "$template" )
else
  # Text is in English. Set SMS text in ASCII form
  ISMSENC="0"
  ISMSTEXT=$( ASCIIStrToURL "$template" )
fi
#
# Delete "+" from phone number
#
if [[ $SMSTO =~ ^[+] ]]; then 
  SMSTO="${SMSTO:1}"
fi
#
# Add "%2B" to phone number
#
if [[ $( echo -n $SMSTO | wc -m ) == "11" ]] && [[ $SMSTO =~ ^[0-9] ]]; then 
    SMSTO=$( echo "%2B" )$SMSTO
else
   echo "Please enter phone number in 11-digit international format."
   exit 1;
fi


# Send sms to iSMS Server
#
FULLURL=$( echo "http://$ISMSSRV/sendmsg?user=$ISMSUSR&passwd=$ISMSPWD&cat=1&enc=$ISMSENC&priority=$ISMSPRIO&modem=$ISMSMODEM&to=$SMSTO&text=$ISMSTEXT" )
wget -q $FULLURL
