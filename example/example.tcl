#!/usr/bin/env wish
package require XTk
package require Img

set generatedCode [xtk::load example.xml]

puts $generatedCode

xtk::run $generatedCode

$::example::buttonClose configure -text "Exit"

proc example::bindCallback {path args} {
	puts "Callback from '$path' -> '$args'"
}
