#!/usr/bin/env tclsh
package require XTk

if {[catch {
	package require tkpng
} err]} {
	puts "Img not loaded, can't display some images"
}
proc generateCode {input output} {
	if {![file exists $input]} { puts "Input file does not exist!"; return }
	if {[file exists $output]} { puts "Output file already exists!"; return }
	set outfl [open $output w+]
	puts $outfl [::xtk::load $input]
	close $outfl
}

proc previewCode {file} {
	if {![file exists $file]} { puts "File does not exist!"; return }
	puts [::xtk::load $file]
}

proc preview {file} {
	if {![file exists $file]} { puts "File does not exist!"; return }
	::xtk::run [::xtk::load $file]
	vwait foo
}

set command [lindex $argv 0]
set p1 [lindex $argv 1]
set p2 [lindex $argv 2]
if {$command eq "generate"} {
	if {[llength $argv] != 3} {
		puts "[info script] generate ..input ..output"
		exit 0
	}
	generateCode $p1 $p2
} elseif {$command eq "previewcode"} {
	if {[llength $argv] != 2} {
		puts "[info script] previewcode ..input"
		exit 0
	}
	previewCode $p1
} elseif {$command eq "preview"} {
	if {[llength $argv] != 2} {
		puts "[info script] preview ..input"
		exit 0
	}
	preview $p1
}
exit 1
