#!/usr/bin/env wish
source ../XTk.tcl

xtk::run [xtk::load example.xml]

$::foo::hitherebutton configure -text "CHANGED BUTTON TEXT"

