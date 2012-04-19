package provide XTk 0.1

package require tdom

namespace eval xtk {
	namespace import ::tcl::mathop::*
	variable sys

	set sys(pathCounter) [dict create]
	set sys(currentPackCommand) ""
	set sys(commandsToExecute) [list]

	proc load {file} {
		variable sys
		if {![file exists $file]} {
			error "File not found: $file"
		}
		set data [read [set fl [open $file r]]];close $fl
		dom setStoreLineColumn true
		set doc [dom parse $data]
		
		set xtkElement [$doc getElementsByTagName "xtk"]

		set namespace [initNamespace $xtkElement]
		traverseTree . 0 $namespace $xtkElement
		return $sys(commandsToExecute)
	}

	proc run {commands} {
		foreach command $commands {
			puts "$command"
			eval $command
		}
	}

	proc initNamespace {xtkElement} {
		if {![$xtkElement hasAttribute "namespace"]} {
			error "line [$xtkElement getLine]: The namespace attribute must be provided for the xtk element"
		}
		set namespace [$xtkElement getAttribute "namespace"]
		if {$namespace eq ""} {
			error "line [$xtkElement getLine]: The namespace attribute of the xtk element must not be empty"
		}
		namespace eval ::${namespace} { }
		return $namespace
	}

	proc traverseTree {currentPath hierarchielevel namespace element} {
		variable sys

		foreach child [$element childNodes] {

			if {[isPack $child]} {
				set sys(currentPackCommand) [getPackOptions $namespace $child]
				traverseTree $currentPath $hierarchielevel $namespace $child
				continue
			} else {
				set parent [[$child parentNode] nodeName]
				if {$parent ne "pack"} {
					error "line [$child getLine]: you must surround widget elements with pack elements: line"
				}
			}

			set nodeName [$child nodeName]
			set path [getUniquePathSegmentForLevel $hierarchielevel $currentPath]
			set nodeName [$child nodeName]
			set attributes [$child attributes]

			handleVariableAttribute $namespace $path $child

			set tkCommand [string trim "$nodeName $path [getOptionsFromAttributes $namespace $child $attributes]"]

			addToCommandList "[packTkCommand $sys(currentPackCommand) $tkCommand]"
			# recursive -> nesting
			if {$nodeName eq "frame"} {
				traverseTree $path [expr {$hierarchielevel + 1}] $namespace $child
			}
		}	
	}

	proc isPack {element} {
		set nodeName [$element nodeName]
		return [expr {$nodeName eq "pack"}]
	}

	proc getPackOptions {namespace element} {
		return [getOptionsFromAttributes $namespace $element [$element attributes]]
	}

	proc packTkCommand {packOptions tkCommand} {
		return "pack \[$tkCommand\] $packOptions"
	}

	proc handleVariableAttribute {namespace path element} {
		if {[hasVariableAttribute $element]} {
			set variable [getVariableAttribute $element]
			 addToCommandList "namespace eval ::${namespace} { set $variable $path }"
		}
	}

	proc addToCommandList {command} {
		variable sys
		lappend sys(commandsToExecute) $command
	}

	proc hasVariableAttribute {element} {
		return [$element hasAttribute "variable"]
	}

	proc getVariableAttribute {element} {
		return [$element getAttribute "variable"]
	}

	proc getOptionsFromAttributes {namespace element attributes} {
		set tkAttributes [list]
		set tkAttributeValues [list]

		foreach attribute $attributes {
			if {$attribute eq "variable"} {
				continue
			} else {
				lappend tkAttributes -${attribute}
				set value [$element getAttribute $attribute]
				if {[string index $value 0] eq "@"} {
					set value \$::${namespace}::[string range $value 1 end]
				}
				lappend tkAttributeValues $value
			}
		}
		set ret ""
		foreach option $tkAttributes value $tkAttributeValues {
			if {[llength $value] > 1} {
				set value \"$value\"
			}
			append ret "$option $value "
		}
		return $ret
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
