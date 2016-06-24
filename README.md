## Software Watchdog CCU Addon – hm-watchdog
<img src="https://github.com/jens-maus/hm-watchdog/raw/master/www/public/img/logo-large.png" align=right>
A HomeMatic CCU Addon package implementing a software watchdog functionality to monitor all important services a CCU devices requires to function correctly. As soon as the watchdog recognizes a service to be down it will try to restart the service. If a service couldn't be restarted three times in a row the software watchdog will also automatically reboot the CCU device. Furthermore, the watchdog will use the standard CCU notification system to notify the administrator of services that were found to be non-working

## Features
* regularly checks the following CCU services:
  - primary services:
    * ReGaHss
    * rfd
    * hs485
    * HMServer / HMIPServer
  - secondary services:
    * lighttpd
    * ifplugd
    * syslogd/klogd
    * ntpclient
    * watchdog
    * CCU2: udevd
    * CCU2: mutimacd
    * CCU2: ssdpd
  - third-party services:
    * CUxD
* automatically reboots CCU device if one of the services failed 3 times in a row
* automatically executes a ReGa script if one of the services had to be restarted
* RaspberryMatic: automatically loads/initializes hardware watchdog device kernel module

## Supported CCU models
* HomeMatic CCU1
* [HomeMatic CCU2](http://www.eq-3.de/produkt-detail-zentralen-und-gateways/items/homematic-zentrale-ccu-2.html)
* [RaspberryMatic](http://homematic-forum.de/forum/viewtopic.php?f=56&t=26917)

## Installation
1. Download of recent Addon-Release from [Github](https://github.com/jens-maus/hm-watchdog/releases)
2. Installation of Addon archive (```hm-watchdog-X.X.tar.gz```) via WebUI interface of CCU device

## Support
In case of problems/bugs or if you have any feature requests please feel free to open a [new ticket](https://github.com/jens-maus/hm-watchdog/issues) at the Github project pages. To seek for help for configuring/using this Addon please use the following german language based fora thread: [hm-watchdog](http://homematic-forum.de/forum/viewtopic.php?f=18&t=31581).

## License
The use and development of this addon is based on version 3 of the LGPL open source license.

## Authors
Copyright (c) 2015-2016 Jens Maus &lt;mail@jens-maus.de&gt;
