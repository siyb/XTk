#!/usr/bin/env wish
source ../XTk.tcl

set generatedCode [xtk::load example.xml]

puts $generatedCode

xtk::run $generatedCode

$::example::buttonClose configure -text "Exit"

proc example::bindCallback {path args} {
	puts "Callback from '$path' -> '$args'"
}
