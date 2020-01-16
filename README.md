## Software Watchdog CCU Addon – hm-watchdog
<img src="https://github.com/jens-maus/hm-watchdog/raw/master/www/public/img/logo-large.png" align=right>

[![Current Release](https://img.shields.io/github/release/jens-maus/hm-watchdog.svg?style=flat-square)](https://github.com/jens-maus/hm-watchdog/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jens-maus/hm-watchdog/latest/total.svg?style=flat-square)](https://github.com/jens-maus/Rhm-watchdog/releases/latest)
[![Issues](https://img.shields.io/github/issues/jens-maus/hm-watchdog.svg?style=flat-square)](https://github.com/jens-maus/hm-watchdog/issues)
![License](https://img.shields.io/github/license/jens-maus/hm-watchdog.svg?style=flat-square)
[![Donate](https://img.shields.io/badge/donate-PayPal-green.svg?style=flat-square)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL)

A HomeMatic CCU Addon package implementing a software watchdog functionality to monitor all important services a CCU devices requires to function correctly. As soon as the watchdog recognizes a service to be down it will try to restart the service. If a service couldn't be restarted three times in a row the software watchdog will also automatically reboot the CCU device. Furthermore, the watchdog will use the standard CCU notification system to notify the administrator of services that were found to be non-working

## Features
* regularly checks the following CCU services:
  - primary services:
    * ReGaHss
    * rfd
    * hs485d
    * HMIPServer
    * mutimacd
    * ssdpd
    * eq3configd
  - secondary services:
    * lighttpd
    * ifplugd
    * syslogd / klogd
    * ntpclient / ntpd
    * watchdog
    * udevd
    * sshd
    * crond
    * CCU3: rngd
    * CCU3: irqbalance
    * CCU3: dbus
    * CCU3: snmpd
  - third-party services:
    * CUxD
* automatically reboots CCU device if one of the services failed 3 times in a row
* automatically executes a ReGa script if one of the services had to be restarted

## Supported CCU models
* [HomeMatic CCU3](https://www.eq-3.de/produkte/homematic/zentralen-und-gateways/smart-home-zentrale-ccu3.html)
* [HomeMatic CCU2](https://www.eq-3.de/produkt-detail-zentralen-und-gateways/items/homematic-zentrale-ccu-2.html)
* HomeMatic CCU1

**WARNING:**
Please note that the use of this Addon with RaspberryMatic is **NOT** required anymore and discouraged/not adviced anymore since it will otherwise cause problems!

## Installation
1. Download of recent Addon-Release from [Github](https://github.com/jens-maus/hm-watchdog/releases)
2. Installation of Addon archive (```hm-watchdog-X.X.tar.gz```) via WebUI interface of CCU device

## Support
In case of problems/bugs or if you have any feature requests please feel free to open a [new ticket](https://github.com/jens-maus/hm-watchdog/issues) at the Github project pages. To seek for help for configuring/using this Addon please use the following german language based fora thread: [hm-watchdog](http://homematic-forum.de/forum/viewtopic.php?f=18&t=31581).

## License
The use and development of this addon is licensed under the conditions of the [Apache License 2.0](https://opensource.org/licenses/Apache-2.0).

## Authors
Copyright (c) 2015-2020 Jens Maus &lt;mail@jens-maus.de&gt;
