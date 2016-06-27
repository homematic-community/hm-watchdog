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

ADDONNAME=hm-watchdog
ADDONDIR=/usr/local/addons/${ADDONNAME}
STATUS_FILE=/var/run/${ADDONNAME}.tmp
MAX_THRESHOLD=2

notify_user()
{
  notify_text="${1}"

  # check if a rega-based notify script exists and if so we send it to tclrega.exe
  # for execution
  if [ -e ${ADDONDIR}/etc/notify.rega ]; then
    # lets load the user configured rega script and replace "${notify_text}" with 
    # the supplied text in this function.
    postbody=$(grep -v "^!" ${ADDONDIR}/etc/notify.rega | sed -e "s/<NOTIFY_TXT>/${notify_text}/")
    if [ -n "${postbody}" ]; then
      wget -q -O - --post-data "${postbody}" "http://127.0.0.1:8181/tclrega.exe"
    fi
  fi
}

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
  id=${2}

  # check if the caller supplied a specific id
  if [ -z "${id}" ]; then
    id=??
  fi

  # check if the service init file exists at all or not
  if [ -e /etc/init.d/S${id}${name} ]; then

    # now check if this service is down already > MAX_THRESHOLD
    # and if so we do a reboot instead
    if [ -f ${STATUS_FILE} ] &&
       [ $(grep "^${name}" ${STATUS_FILE} | wc -l) -gt ${MAX_THRESHOLD} ]; then
      # lets notify the user
      notify_user "hm-watchdog: CCU restarted due to service ${name} down >${MAX_THRESHOLD} times."

      /usr/bin/logger -t hm-watchdog -p err "${name} service down for >${MAX_THRESHOLD} iterations. Rebooting CCU" 2>&1 >/dev/null

      # lets wait 5 seconds before we actually reboot to give the notification
      # the time to send out all information
      sleep 5
      sync
      /sbin/reboot

      exit 1
    fi

    # restart the service
    /etc/init.d/S${id}${name} stop
    sleep 3
    /etc/init.d/S${id}${name} start

    # lets write down which service actually failed.
    echo ${name} >>${STATUS_FILE}

    msg=$(/usr/bin/logger -s -t hm-watchdog -p warn "${name} restarted" 2>&1)
    echo "$(date +'%Y-%m-%d %T') - ${msg}" >>/var/log/hm-watchdog.log

    # lets notify the user
    notify_user "hm-watchdog: ${name} restarted"
  fi
}

# check for the ReGaHss beast (ALL: /etc/init.d/S70ReGaHss)
if [ $(ps | grep "/bin/ReGaHss " | grep -v grep | wc -l) -lt 1 ]; then
  # ReGaHss has crashed (as usual)
  restart_service "ReGaHss"
else
  ack_service "ReGaHss"
fi

# check rfd to run properly (ALL: /etc/init.d/S60rfd)
if [ -e /etc/config/rfd.conf ] &&
   [ $(ps | grep "/bin/rfd " | grep -v grep | wc -l) -lt 1 ]; then
  # rfd is not running, restart it
  restart_service "rfd"
else
  ack_service "rfd"
fi

# check hs485d (ALL: /etc/init.d/S60hs485d)
if [ -e /etc/config/hs485d.conf ] &&
   [ $(ps | grep "bin/hs485d " | grep -v grep | wc -l) -lt 1 ]; then
  # hs485d is not running, restart it
  restart_service "hs485d" 60
else
  ack_service "hs485d"
fi

# check ntpclient (ALL: /etc/init.d/S50SetClock)
if [ -e /etc/config/ntpclient ] &&
   [ $(ps | grep "ntpclient" | grep -v grep | wc -l) -lt 1 ]; then
  # ntpclient is not running
  restart_service "SetClock"
else
  ack_service "SetClock"
fi

# check syslogd/klogd (ALL: /etc/init.d/S01logging)
if [ -e /etc/config/syslog ] &&
   ( [ $(ps | grep "/sbin/syslogd" | grep -v grep | wc -l) -lt 1 ] ||
     [ $(ps | grep "/sbin/klogd" | grep -v grep | wc -l) -lt 1 ] ); then
  # syslogd/klogd not running
  restart_service "logging"
else
  ack_service "logging"
fi

# check udevd (CCU2: /etc/init.d/S10udev)
if [ -e /lib/udev/udevd ] &&
   [ $(ps | grep "/lib/udev/udevd" | grep -v grep | wc -l) -lt 1 ]; then
  # udevd is not running anymore
  restart_service "udev"
else
  ack_service "udev"
fi

# check ifplugd (ALL: /etc/init.d/S45ifplugd)
if [ $(ps | grep "/usr/sbin/ifplugd" | grep -v grep | wc -l) -lt 1 ]; then
  # ifplugd is not running anymore
  restart_service "ifplugd"
else
  ack_service "ifplugd"
fi

# check for ssdpd / eq3configcmd (CCU2: /etc/init.d/S50eq3configd)
if [ $(ps | grep "/bin/ssdpd" | grep -v grep | wc -l) -lt 1 ]; then
  # ssdpd is not running anymore
  restart_service "eq3configd"
else
  ack_service "eq3configd"
fi

# check for HMIPServer (Firmware >= 2.17.15) or HMServer
if [ $(ps | grep -E "/opt/HMServer/HMI?P?Server\.jar" | grep -v grep | wc -l) -lt 1 ]; then
  # HMServer.jar not running
  restart_service "HMServer"
else
  ack_service "HMServer"
fi

# check multimacd (CCU2: /etc/init.d/S60multimacd)
if [ -e /etc/config/multimacd.conf ] &&
   [ $(ps | grep "/bin/multimacd" | grep -v grep | wc -l) -lt 1 ]; then
  # multimacd is not running
  restart_service "multimacd"
else
  ack_service "multimacd"
fi

# check lighthttpd (ALL: /etc/init.d/S50lighttpd)
if [ -e /etc/lighttpd/lighttpd.conf ] &&
   [ $(ps | grep "/usr/sbin/lighttpd" | grep -v grep | wc -l) -lt 1 ]; then
  # multimacd is not running
  restart_service "lighttpd"
else
  ack_service "lighttpd"
fi

# check watchdog (ALL: /etc/init.d/S15watchdog)
if [ -e /dev/watchdog ]; then
  if [ $(ps | grep "/dev/watchdog" | grep -v grep | wc -l) -lt 1 ]; then
    # watch is not running
    restart_service "watchdog"
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
  restart_service "cuxd"
else
  ack_service "cuxd"
fi
