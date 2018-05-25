#!/bin/sh
#
# Watchdog CCU Addon Script
#
# This script is regularly executed and checks if important
# CCU services are still running and if not restarts them while
# notifying the user accordingly.
#
# Copyright (c) 2015-2018 Jens Maus <mail@jens-maus.de>
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
  if [[ -e "${ADDONDIR}/etc/notify.rega" ]]; then
    # lets load the user configured rega script and replace "${notify_text}" with 
    # the supplied text in this function.
    postbody=$(grep -v "^!" ${ADDONDIR}/etc/notify.rega | sed -e "s/<NOTIFY_TXT>/${notify_text}/")
    if [[ -n "${postbody}" ]]; then
      /usr/bin/wget -q -O - --post-data "${postbody}" "http://127.0.0.1:8181/tclrega.exe" 2>/dev/null >/dev/null
    fi
  elif [[ -x "/bin/triggerAlarm.tcl" ]]; then
    /bin/triggerAlarm.tcl "${notify_text}"
  fi
}

ack_service()
{
  name=${1}

  # lets remove any lines with "$name" from our
  # status file
  if [[ -e ${STATUS_FILE} ]]; then
    tmp=$(grep -v "^${name}\$" ${STATUS_FILE})
    echo "${tmp}" >${STATUS_FILE}
  fi
}

restart_service()
{
  name=${1}
  id=${2}

  # check if the caller supplied a specific id
  if [[ -z "${id}" ]]; then
    id=??
  fi

  # check if the service init file exists at all or not
  if [[ -x /etc/init.d/S${id}${name} ]]; then

    # now check if this service is down already > MAX_THRESHOLD
    # and if so we do a reboot instead
    if [[ -f ${STATUS_FILE} ]] &&
       [[ $(grep "^${name}" ${STATUS_FILE} | wc -l) -gt ${MAX_THRESHOLD} ]]; then
      # lets notify the user
      notify_user "hm-watchdog: CCU restarted due to service ${name} down >${MAX_THRESHOLD} times."

      /usr/bin/logger -t hm-watchdog -p err "${name} service down for >${MAX_THRESHOLD} iterations. Rebooting CCU" 2>/dev/null >/dev/null

      # lets wait 5 seconds before we actually reboot to give the notification
      # the time to send out all information
      sleep 5
      sync
      /sbin/reboot

      exit 1
    fi

    # restart the service
    /etc/init.d/S${id}${name} stop 2>/dev/null >/dev/null
    sleep 3
    /etc/init.d/S${id}${name} start 2>/dev/null >/dev/null

    # lets write down which service actually failed.
    echo ${name} >>${STATUS_FILE}

    msg=$(/usr/bin/logger -s -t hm-watchdog -p warn "${name} restarted" 2>&1)
    echo "$(date +'%Y-%m-%d %T') - ${msg}" >>/var/log/hm-watchdog.log

    # lets notify the user
    notify_user "hm-watchdog: ${name} restarted"
  fi
}

check_service()
{
  name=${1}
  search=${2}
  id=${3}

  # check if the caller supplied a specific id
  if [[ -z "${id}" ]]; then
    id=??
  fi

  if [[ -z "${search}" ]]; then
    search=${name}
  fi

  if [[ -x /etc/init.d/S${id}${name} ]]; then
    if [[ $(ps -o comm | grep -E "${search}" | wc -l) -lt 1 ]]; then
      restart_service "${name}" "${id}"
    else
      ack_service "${name}"
    fi
  fi
}

###########################################################
# main operations start here

# check watchdog (ALL: /etc/init.d/S15watchdog)
if [[ -c /dev/watchdog ]]; then
  check_service "watchdog"
fi

# check syslogd/klogd (ALL: /etc/init.d/S01logging)
if [[ -e /etc/config/syslog ]]; then
  check_service "logging" "syslogd"
  check_service "logging" "klogd"
fi

# check udevd (ALL: /etc/init.d/S10udev)
check_service "udev" "udevd"

# check irqbalance (RaspberryMatic: /etc/init.d/S13irqbalance)
check_service "irqbalance"

# check rngd (RaspberryMatic: /etc/init.d/S21rngd)
check_service "rngd"

# check dbus (RaspberryMatic: /etc/init.d/S30dbus)
check_service "dbus"

# check ifplugd (ALL: /etc/init.d/S45ifplugd)
check_service "ifplugd"

# check ntpd (RaspberryMatic: /etc/init.d/S48ntp)
if [[ -x /etc/init.d/S??ntp ]] &&
   [[ -e /etc/config/ntpclient ]] && [[ -e /var/status/hasNTP ]]; then
  check_service "ntp" "ntpd"
fi

# check ntpclient (CCU1/CCU2: /etc/init.d/S50SetClock)
if [[ -x /etc/init.d/S??SetClock ]] &&
   [[ -e /etc/config/ntpclient ]] && [[ -e /var/status/hasNTP ]]; then
  check_service "SetClock" "ntpclient"
fi

# check for ssdpd (RaspberryMatic: /etc/init.d/S50ssdpd)
check_service "ssdpd"

# check for eq3configd (ALL: /etc/init.d/S50eq3configd)
if [[ -x /etc/init.d/S??eq3configd ]]; then
  if [[ ! -e /etc/init.d/S??ssdpd ]]; then
    check_service "eq3configd" "ssdpd" # CCU2 only
  fi
  check_service "eq3configd" "eq3configd"
fi

# check lighttpd (ALL: /etc/init.d/S50lighttpd)
check_service "lighttpd"

# check sshd (ALL: /etc/init.d/S50sshd)
if [[ -e /etc/config/sshEnabled ]]; then
  check_service "sshd"
fi

# check CUxD (if present: /etc/init.d/S55cuxd)
check_service "cuxd"

# check snmpd (RaspberryMatic: /etc/init.d/S59snmpd)
check_service "snmpd"

# check hs485d (ALL: /etc/init.d/S60hs485d)
if grep -q BidCos-Wired /etc/config/InterfacesList.xml; then
  check_service "hs485d" "hs485d" 60
fi

# check multimacd (ALL: /etc/init.d/S60multimacd)
check_service "multimacd"

# check rfd to run properly (ALL: /etc/init.d/S60rfd)
if grep -q BidCos-RF /etc/config/InterfacesList.xml; then
  check_service "rfd"
fi

# check for HMIPServer (ALL: /etc/init.d/S62HMServer)
if [[ -x /etc/init.d/S??HMServer ]]; then
  if [[ $(ps -o args | grep -E "HMIPServer\.jar" | grep -v grep | wc -l) -lt 1 ]]; then
    # HMIPServer.jar not running
    restart_service "HMServer"
  else
    ack_service "HMServer"
  fi
fi

# check for the ReGaHss (ALL: /etc/init.d/S70ReGaHss)
check_service "ReGaHss"

# check crond (RaspberryMatic: /etc/init.d/S71crond)
check_service "crond"
