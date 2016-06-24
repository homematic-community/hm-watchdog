set ADDONNAME "hm-watchdog"
set NOTIFY_REGA "/usr/local/addons/hm-watchdog/etc/notify.rega"

array set args { command INV HM_WATCHDOG_NOTIFY {} HM_WATCHDOG_INTERVAL {} }

proc utf8 {hex} {
    set hex [string map {% {}} $hex]
    return [encoding convertfrom utf-8 [binary format H* $hex]]
}

proc url-decode str {
    # rewrite "+" back to space
    # protect \ from quoting another '\'
    set str [string map [list + { } "\\" "\\\\" "\[" "\\\["] $str]

    # Replace UTF-8 sequences with calls to the utf8 decode proc...
    regsub -all {(%[0-9A-Fa-f0-9]{2})+} $str {[utf8 \0]} str

    # process \u unicode mapped chars and trim whitespaces
    return [string trim [subst -novar  $str]]
}

proc str-escape str {
    set str [string map -nocase { 
              "\"" "\\\""
              "\$" "\\\$"
              "\\" "\\\\"
              "`"  "\\`"
             } $str]

    return $str
}

proc str-unescape str {
    set str [string map -nocase { 
              "\\\"" "\""
              "\\\$" "\$"
              "\\\\" "\\"
              "\\`"  "`"
             } $str]

    return $str
}


proc parseQuery { } {
    global args env
    
    set query [array names env]
    if { [info exists env(QUERY_STRING)] } {
        set query $env(QUERY_STRING)
    }
    
    foreach item [split $query &] {
        if { [regexp {([^=]+)=(.+)} $item dummy key value] } {
            set args($key) $value
        }
    }
}

proc loadFile { fileName } {
    set content ""
 
    if [file exists $fileName] {
      set fd -1
      set fd [ open $fileName r]
      if { $fd > -1 } {
        set content [read $fd]
        close $fd
      }
    }
    
    return $content
}

proc loadConfigFile { } {
    global NOTIFY_REGA HM_WATCHDOG_NOTIFY HM_WATCHDOG_INTERVAL
    set conf ""
    catch {set conf [loadFile $NOTIFY_REGA]}

    if { [string trim "$conf"] != "" } {
      set HM_WATCHDOG_NOTIFY $conf
    }

    if { [ catch {
      set HM_WATCHDOG_INTERVAL [exec grep HM_WATCHDOG_INTERVAL /usr/local/addons/hm-watchdog/etc/hm-watchdog.conf | grep -v grep | cut -f2 -d {=}]
    } err ] } {
      set HM_WATCHDOG_INTERVAL "0"
    }
}

proc saveConfigFile { } {
    global NOTIFY_REGA args
        
    set HM_WATCHDOG_NOTIFY [url-decode $args(HM_WATCHDOG_NOTIFY)]
    set HM_WATCHDOG_INTERVAL [url-decode $args(HM_WATCHDOG_INTERVAL)]

    # output the whole content of WATCHDOG_NOTIFY to our notify.rega file
    set fd [open $NOTIFY_REGA w]

    # convert all \r\n (CRLF) to \n (LF) only
    set HM_WATCHDOG_NOTIFY [string map -nocase { "\r\n" "\n" } $HM_WATCHDOG_NOTIFY]

    # write out the notify script text and close the file
    puts $fd $HM_WATCHDOG_NOTIFY
    close $fd

    # save the interval value to our config file
    set fd [open /usr/local/addons/hm-watchdog/etc/hm-watchdog.conf w]
    puts $fd HM_WATCHDOG_INTERVAL=$HM_WATCHDOG_INTERVAL
    close $fd

    # we have updated our configuration so lets
    # stop/restart hm-watchdog
    if { $HM_WATCHDOG_INTERVAL == 0 } { 
      exec /usr/local/etc/config/rc.d/hm-watchdog stop &
    } else {
      exec /usr/local/etc/config/rc.d/hm-watchdog restart
    }
}
