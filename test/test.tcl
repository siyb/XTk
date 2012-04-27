package require tcltest
namespace import tcltest::*

verbose ptbsel

source ../XTk.tcl

# test generating an error
set failTests [lsort -dictionary [glob fail_*.xml]]
foreach file $failTests {
	test $file {Error test} -body {
		::xtk::load $file
	} -returnCodes error -match glob -result *
}
exit
