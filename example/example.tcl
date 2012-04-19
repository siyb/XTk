#!/usr/bin/env wish
source ../XTk.tcl

set generatedCode [xtk::load example.xml]

puts $generatedCode

xtk::run $generatedCode

$::foo::hitherebutton configure -text "CHANGED BUTTON TEXT"

