#!/usr/bin/env tclsh
package require XTk

if {[catch {
	package require tkpng
} err]} {
	puts "Img not loaded, can't display some images"
}
proc generateCode {input output} {
	if {![file exists $input]} { puts "Input file does not exist!"; return 0 }
	if {[file exists $output]} { puts "Output file already exists!"; return 0 }
	set outfl [open $output w+]
	puts $outfl [::xtk::load $input]
	close $outfl
	return 1
}

proc previewCode {file} {
	if {![file exists $file]} { puts "File does not exist!"; return 0 }
	puts [::xtk::load $file]
	return 1
}

proc preview {file} {
	if {![file exists $file]} { puts "File does not exist!"; return 0 }
	::xtk::run [::xtk::load $file]
	return 1
}

set command [lindex $argv 0]
set p1 [lindex $argv 1]
set p2 [lindex $argv 2]
if {$command eq "generate"} {
	if {[llength $argv] != 3} {
		puts "[info script] generate ..input ..output"
		exit 0
	}
	if {![generateCode $p1 $p2]} { exit 0 }
} elseif {$command eq "previewcode"} {
	if {[llength $argv] != 2} {
		puts "[info script] previewcode ..input"
		exit 0
	}
	if {![previewCode $p1] != 0} { exit 0 }
} elseif {$command eq "preview"} {
	if {[llength $argv] != 2} {
		puts "[info script] preview ..input"
		exit 0
	}
	if {![preview $p1]} { exit 0 }
	tkwait window .
} else {
	puts "generate ..input ..output\npreviewcode ..input\npreview ..input"
}
exit 1
