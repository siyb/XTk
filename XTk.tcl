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
		traverseTree . 0 $namespace $xtkElement
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

	proc traverseTree {currentPath hierarchielevel namespace element} {
		foreach child [$element childNodes] {

			set path [getUniquePathSegmentForLevel $hierarchielevel $currentPath]
			set nodeName [$child nodeName]
			set attributes [$child attributes]

			set tkAttributes [list]
			set tkAttributeValues [list]

			foreach attribute $attributes {
				if {$attribute eq "variable"} {
				} else {
					lappend tkAttributes -${attribute}
					lappend tkAttributeValues [$child getAttribute $attribute]
				}
			}
			set tkCommand "$nodeName $path"

			foreach option $tkAttributes value $tkAttributeValues {
				set tkCommand "$tkCommand $option $value"
			}

			# recursive -> nesting
			if {$nodeName eq "frame"} {
				traverseTree $path [expr {$hierarchielevel + 1}] $namespace $child
			}
		}	
	}

	proc getUniquePathSegmentForLevel {level currentPath} {
		variable sys
		if {$currentPath eq "."} {
			set sep ""
		} else {
			set sep "."
		}
		if {[dict exists $sys(pathCounter) $level]} {
			dict incr sys(pathCounter) $level
			return ${currentPath}${sep}[dict get $sys(pathCounter) $level]
		} else {
			dict set sys(pathCounter) $level 0
			return ${currentPath}${sep}0
		}
	}

}

xtk::load /home/siyb/code/XTk/example.xml
