## About

**notification-to-isms** - Script for SMS notifications for **Icinga** via **MultiTech MultiModem iSMS Server**
 
Tested on:
- Debian GNU/Linux 10.9 (Buster), Icinga r2.8.8
- Multi-Tech MultiModem iSMS Server SF800-G with firmware 1.51.28

The latest version of the iSMS firmware can be downloaded from the link: 
ftp://ftp.multitech.com/engineering/unofficial-releases/iSMS%20(Formerly%20SMSFinder)/Firmware/

In the iSMS device settings, you need to set the following parameters:
1) Menu "SMS Services" -> "SMS Settings" need to enable options "Enable PDU Mode" and "Concatenate Multipart Outbound Messages"
2) Menu "SMS Services" -> "SMS Settings" in "ASCII 7-bit Configuration" need to change option "Character Set" to "3GPP 23.038"
3) Menu "SMS Services" -> "SMS API" in "HTTP API Configuration" need to change option "Preferred Character Set" to "UTF-8"

Copy script on Icinga server to /etc/icinga2/scripts/notification-to-isms.sh
 
## Usage

Options:

```
$ ./notification-to-isms.sh [OPTIONS]

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

```

Testing for Host mode:

```
# ./notification-to-isms.sh --plugin-mode host-mode \
--notification-type 'PROBLEM' \
--long-datetime '2021-04-19 06:28:41' \
--host-displayname 'RT001' --host-address '10.10.50.1' \
--item-comment 'Router Mikrotik - Телеком.узел Соловки, стойка 4' \
--host-output 'PING CRITICAL - Packet loss = 100%' \
--notification-autor 'petya' --notification-comment 'plugin test' \
--isms-server 'isms.holding.com:81' --isms-user 'icinga' --isms-password 'myp!w0D' \
--isms-priority '3' --isms-modem-num '0' \
--sms-to '79128887766'
```

Testing for Service mode:

```
# ./notification-to-isms.sh --plugin-mode service-mode \
 --notification-type RECOVERY \
 --notification-autor 'petya' --notification-comment 'проверка плагина' \
 --long-datetime '2021-04-19 06:28:41' \
 --host-displayname 'UPS011' --service-desc 'APC UPS Input Lines' \
 --service-output "OK: voltage: 230.1 V, frequence: 50 Hz"  \
 --item-comment "ИБП APC Smart-UPS 5000 - ЦОД, стойка 5" \
 --isms-server "isms.holding.com:81" --isms-user 'icinga' --isms-password='myp!w0D' \
 --isms-priority=2 --isms-modem-num=1 \
 --sms-to "72223334455"
```

Icinga Director integration manual (in Russian):

[Развёртывание и настройка Icinga 2 на Debian 8.6. Часть 14. Настройка SMS оповещений в Icinga Director 1.3](https://blog.it-kb.ru/2017/09/15/deploy-and-configure-icinga-2-on-debian-8-part-14-icinga-director-1-3-and-sms-notifications-with-plugin-command-and-custom-shell-script/)
