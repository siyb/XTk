package provide XTk 0.1

package require tdom

namespace eval xtk {
	namespace import ::tcl::mathop::*
	variable sys

	# used to store a counter for each hierarchie level.
	# will be incremented every time a widget is create.
	set sys(pathCounter) [dict create]

	# stores the most recent pack command to be invoked
	# on child widgets. 
	set sys(currentPackCommand) ""

	# TODO: more sophisticated data structure in order to
	# provide better code generation
	#
	# a list of Tk commands to be executed. Commands stored
	# here are generated from xml
	set sys(commandsToExecute) [list]

	set sys(geomanager) [list pack place grid]

	# a list of ttk widgets that is used to optain validation data
	set sys(widgets,ttk) [list ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::label ttk::labelframe ttk::menubutton ttk::notebook ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator ttk::sizegrip ttk::spinbox ttk::treeview]

	# a list of tk widgets that is used to obtain validation data
	set sys(widgets,default) [list button canvas checkbutton entry frame label labelframe listbox menu menubutton message panedwindow radiobutton scale scrollbar spinbox text]

	# a dict containing widget option validation data after
	# obtainValidationData has been called
	set sys(validation,widget,options) [dict create]

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
		set ttk [initTtk $xtkElement]

		traverseTree . 0 $namespace $xtkElement $ttk
		return $sys(commandsToExecute)
	}

	proc run {commands} {
		foreach command $commands {
			puts "$command"
			eval $command
		}
	}

	proc initTtk {xtkElement} {
		return [$xtkElement getAttribute "ttk" 0]
	}

	proc initNamespace {xtkElement} {
		if {![$xtkElement hasAttribute "namespace"]} {
			throwNodeErrorMessage $xtkElement "The namespace attribute must be provided for the xtk element"
		}
		set namespace [$xtkElement getAttribute "namespace"]
		if {$namespace eq ""} {
			throwNodeErrorMessage $xtkElement "The namespace attribute of the xtk element must not be empty"
		}
		namespace eval ::${namespace} { }
		return $namespace
	}

	proc traverseTree {currentPath hierarchielevel namespace element ttk} {
		variable sys

		foreach child [$element childNodes] {

			set nodeName [$child nodeName]

			if {$ttk} {
				set nodeName ttk::${nodeName}
			}

			if {[isPack $child]} {
				set sys(currentPackCommand) [getPackOptions $namespace $child]
				traverseTree $currentPath $hierarchielevel $namespace $child $ttk
				continue
			} else {
				if {![isWidgetValid $nodeName]} {
					throwNodeErrorMessage $child "the widget '$nodeName' does not exist"
				}
				set parent [[$child parentNode] nodeName]
				if {$parent ne "pack"} {
					throwNodeErrorMessage $child "you must surround widget elements with pack elements"
				}
			}

			set path [getUniquePathSegmentForLevel $hierarchielevel $currentPath]
			set nodeName [$child nodeName]
			set attributes [$child attributes]

			handleVariableAttribute $namespace $path $child

			set tkCommand [string trim "${nodeName} $path [getOptionsFromAttributes $namespace $child $attributes]"]

			addToCommandList "[packTkCommand $sys(currentPackCommand) $tkCommand]"
			# recursive -> nesting
			if {$nodeName eq "frame"} {
				traverseTree $path [expr {$hierarchielevel + 1}] $namespace $child $ttk
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

	proc throwNodeErrorMessage {node message} {
		error "line: [$node getLine] column: [$node getColumn] -> $message"
	}

	proc obtainValidationData {} {
		variable sys
		set counter 0
		foreach {key widgets} [array get sys widgets,*] {
			foreach widget $widgets {
				if {[catch {
					$widget .${counter}
					set options [.${counter} configure]
					set supportedWidgetOptions [getAvailableOptionsFromOptionList $options]
					destroy .${counter}
					incr counter
					addWidgetValidationData $widget $supportedWidgetOptions
				} err]} {
					puts "could not optain configuration data for $widget: $::errorInfo"
				}
			}
		}
	}

	proc getAvailableOptionsFromOptionList {optionList} {
		set ret [list]
		foreach option $optionList {
			foreach item $option {
				if {[string index $item 0] eq "-"} {
					lappend ret $item
				} else {
					break
				}
			}
		}
		return $ret
	}

	proc addWidgetValidationData {widget supportedWidgetOptions} {
		variable sys
		dict set sys(validation,widget,options) $widget $supportedWidgetOptions
	}

	proc isWidgetValid {widget} {
		variable sys
		return [dict exists $sys(validation,widget,options) $widget]
	}

	proc isOptionValidForWidget {widget option} {
		variable
		return [in $option [dict get $sys(validation,widget,options) $widget]]
	}
	
	obtainValidationData

	namespace export run load
}
