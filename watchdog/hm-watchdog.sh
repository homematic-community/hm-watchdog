#!/bin/sh
#
# Watchdog CCU Addon Script
#
# This script is regularly executed and checks if important
# CCU services are still running and if not restarts them while
# notifying the user accordingly.
#
# Copyright (c) 2015-2016 Jens Maus <mail@jens-maus.de>
#

STATUS_FILE=/var/run/hm-watchdog.tmp
MAX_THRESHOLD=3

ack_service()
{
  name=${1}

  # lets remove any lines with "$name" from our
  # status file
  if [ -e ${STATUS_FILE} ]; then
    tmp=$(grep -v "^${name}\$" ${STATUS_FILE})
    echo "${tmp}" >${STATUS_FILE}
  fi
}

restart_service()
{
  name=${1}
  service=${2}

  # now check if this service is down already > MAX_THRESHOLD
  # and if so we do a reboot instead
  if [ -e ${STATUS_FILE} ] &&
     [ $(grep "^${name}\$" ${STATUS_FILE} | wc -l) -gt ${MAX_THRESHOLD} ]; then
    /usr/bin/logger -t hm-watchdog -p err "${name} service down for >${MAX_THRESHOLD} iterations. Rebooting CCU system" 2>&1 >/dev/null
    /sbin/reboot
    exit 1
  fi

  # restart the service
  ${service} stop
  sleep 3
  ${service} start

  # lets write down which service actually failed.
  echo ${name} >>${STATUS_FILE}

  msg=$(/usr/bin/logger -s -t hm-watchdog -p warn "${name} restarted" 2>&1)
  echo "$(date +'%Y-%m-%d %T') - ${msg}" >>/var/log/hm-watchdog.log
}

# check for the ReGaHss beast (ALL: /etc/init.d/S70ReGaHss)
if [ $(ps | grep "/bin/ReGaHss " | grep -v grep | wc -l) -lt 1 ]; then
  # ReGaHss has crashed (as usual)
  restart_service "ReGaHss" /etc/init.d/S70ReGaHss
else
  ack_service "ReGaHss"
fi

# check rfd to run properly (ALL: /etc/init.d/S60rfd)
if [ -e /etc/config/rfd.conf ] &&
   [ $(ps | grep "/bin/rfd " | grep -v grep | wc -l) -lt 1 ]; then
  # rfd is not running, restart it
  restart_service "rfd" /etc/init.d/S60rfd
else
  ack_service "rfd"
fi

# check hs485d (ALL: /etc/init.d/S49hs485d)
if [ -e /etc/config/hs485d.conf ] &&
   [ $(ps | grep "bin/hs485d " | grep -v grep | wc -l) -lt 1 ]; then
  # hs485d is not running, restart it
  restart_service "hs485" /etc/init.d/S49hs485d
else
  ack_service "hs485"
fi

# check ntpclient (ALL: /etc/init.d/S50SetClock)
if [ -e /etc/config/ntpclient ] &&
   [ $(ps | grep "ntpclient" | grep -v grep | wc -l) -lt 1 ]; then
  # ntpclient is not running
  restart_service "ntpclient" /etc/init.d/S50SetClock
else
  ack_service "ntpclient"
fi

# check syslogd/klogd (ALL: /etc/init.d/S01logging)
if [ -e /etc/config/syslog ] &&
   ( [ $(ps | grep "/sbin/syslogd" | grep -v grep | wc -l) -lt 1 ] ||
     [ $(ps | grep "/sbin/klogd" | grep -v grep | wc -l) -lt 1 ] ); then
  # syslogd/klogd not running
  restart_service "syslogd" /etc/init.d/S01logging
else
  ack_service "syslogd"
fi

# check udevd (CCU2: /etc/init.d/S10udev)
if [ $(grep -q "ccu2-ic200" /etc/config/rfd.conf; echo $?) -eq 0 ] &&
   [ $(ps | grep "/lib/udev/udevd" | grep -v grep | wc -l) -lt 1 ]; then
  # udevd is not running anymore
  restart_service "udevd" /etc/init.d/S10udev
else
  ack_service "udevd"
fi

# check ifplugd (ALL: /etc/init.d/S45ifplugd)
if [[ $(ps | grep "/usr/sbin/ifplugd" | grep -v grep | wc -l) -lt 1 ]]; then
  # ifplugd is not running anymore
  restart_service "ifplugd" /etc/init.d/S45ifplugd
else
  ack_service "ifplugd"
fi

# check for ssdpd / eq3configcmd (CCU2: /etc/init.d/S50eq3configd)
if [[ $(ps | grep "/bin/ssdpd" | grep -v grep | wc -l) -lt 1 ]]; then
  # ssdpd is not running anymore
  restart_service "ssdpd" /etc/init.d/S50eq3configd
else
  ack_service "ssdpd"
fi

# check for HMIPServer vs.HMServer (Firmware 2.17.5+)
if [[ -e /etc/crRFD.conf ]]; then
  # check HMIPServer (Firmware >= 2.17.15: /etc/init.d/S62HMServer)
  if [[ $(ps | grep "/opt/HMServer/HMIPServer.jar" | grep -v grep | wc -l) -lt 1 ]]; then
    # HMIPServer.jar not running
    restart_service "HMIPServer" /etc/init.d/S62HMServer
  else
    ack_service "HMIPServer"
  fi
else
  # check HMServer (Firmware < 2.17.15: /etc/init.d/S61HMServer)
  if [[ $(ps | grep "/opt/HMServer/HMServer.jar" | grep -v grep | wc -l) -lt 1 ]]; then
    # HMServer.jar not running
    restart_service "HMServer" /etc/init.d/S61HMServer
  else
    ack_service "HMServer"
  fi
fi

# check multimacd (CCU2: /etc/init.d/S60multimacd)
if [ -e /etc/config/multimacd.conf ] &&
   [ $(ps | grep "/bin/multimacd" | grep -v grep | wc -l) -lt 1 ]; then
  # multimacd is not running
  restart_service "multimacd" /etc/init.d/S60multimacd
else
  ack_service "multimacd"
fi

# check lighthttpd (ALL: /etc/init.d/S50lighttpd)
if [ -e /etc/lighttpd/lighttpd.conf ] &&
   [ $(ps | grep "/usr/sbin/lighttpd" | grep -v grep | wc -l) -lt 1 ]; then
  # multimacd is not running
  restart_service "lighttpd" /etc/init.d/S50lighttpd
else
  ack_service "lighttpd"
fi

# check watchdog (ALL: /etc/init.d/S15watchdog)
if [ -e /dev/watchdog ]; then
  if [ $(ps | grep "/dev/watchdog" | grep -v grep | wc -l) -lt 1 ]; then
    # watch is not running
    restart_service "watchdog" /etc/init.d/S15watchdog
  else
    ack_service "watchdog"
  fi
else
  # now we have to check if we have to load the corresponding watchdog
  # kernel modul (for RaspberryPi)
  modprobe bcm2708_wdog nowayout=1 heartbeat=15 2>&1 >/dev/null
  if [ $? -eq 0 ] && [ -e /dev/watchdog ]; then
    # now we have a watchdog waiting, lets start the watchdog service
    watchdog -t 5 /dev/watchdog &
  fi
fi

# check CUxD (if present: /etc/init.d/S55cuxd)
if [ -e /usr/local/addons/cuxd ] &&
   [ $(ps | grep "/usr/local/addons/cuxd/cuxd" | grep -v grep | wc -l) -lt 1 ]; then
  # cuxd is not running
  restart_service "cuxd" /etc/init.d/S55cuxd
else
  ack_service "cuxd"
fi
