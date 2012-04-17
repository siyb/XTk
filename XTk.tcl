package provide XTk 0.1

package require tdom

namespace eval xtk {
	variable sys

	set sys(pathCounter) [dict create]

	proc load {file} {
		if {![file exists $file]} {
			error "File not found: $file"
		}
		set data [read [set fl [open $file r]]];close $fl
		set doc [dom parse $data]
		
		set xtkElement [$doc getElementsByTagName "xtk"]

		set namespace [initNamespace $xtkElement]
		traverseTree 0 $namespace $xtkElement
	}

	proc initNamespace {xtkElement} {
		if {![$xtkElement hasAttribute "namespace"]} {
			error "The namespace attribute must be provided for the xtk element"
		}
		set namespace [$xtkElement getAttribute "namespace"]
		if {$namespace eq ""} {
			error "The namespace attribute of the xtk element must not be empty"
		}
		namespace eval ::${namespace} { }
		return $namespace
	}

	proc traverseTree {hierarchielevel namespace xtkElement} {
		foreach child [$xtkElement childNodes] {
			set nodeName [$child nodeName]
			set attributes [$child attributes]
			foreach attribute $attributes {
				if {$attribute eq "variable"} {
				}
			}
			puts "$nodeName | $attributes"
		}	
	}

	proc getUniquePathPartForLevel {level} {
		variable sys
		if {[dict exists $sys(pathCounter) $level]} {
			return [dict incr sys(pathCounter) $level]
		} else {
			dict set sys(pathCounter) $level 0
			return 0
		}
	}

}

xtk::load /home/siyb/code/XTk/example.xml
