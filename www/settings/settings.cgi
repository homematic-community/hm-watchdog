#!/usr/bin/env tclsh
source [file join [file dirname [info script]] inc/settings.tcl]

parseQuery

if { $args(command) == "save" } {
	saveConfigFile
} 

set HM_WATCHDOG_NOTIFY ""
set HM_WATCHDOG_INTERVAL ""

loadConfigFile

if { $args(command) == "defaults" } {
  set HM_WATCHDOG_NOTIFY [loadFile "/usr/local/addons/hm-watchdog/etc/notify.rega_default"]
  set HM_WATCHDOG_INTERVAL "3"
} 

set content [loadFile settings.html]
source [file join [file dirname [info script]] inc/settings1.tcl]
