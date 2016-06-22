regsub -all {<%HM_WATCHDOG_NOTIFY%>} $content [string trim $HM_WATCHDOG_NOTIFY] content
regsub -all {<%HM_WATCHDOG_INTERVAL%>} $content [string trim $HM_WATCHDOG_INTERVAL] content

puts "Content-Type: text/html; charset=utf-8\n\n"
puts $content
