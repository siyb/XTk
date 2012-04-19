package provide XTk 0.1

package require tdom

namespace eval xtk {
	namespace import ::tcl::mathop::*
	variable sys

	# version identifier
	set sys(meta,version) "alpha"

	# used to store a counter for each hierarchie level.
	# will be incremented every time a widget is create.
	set sys(pathCounter) [dict create]

	# stores the most recent pack command to be invoked
	# on child widgets. 
	set sys(currentGeomanagerCommand) ""

	set sys(ttk) 0

	# this dict holds data that is required to generate
	# TCL/TK code from XML
	set sys(generate,code) [dict create]

	# a list of available geometry managers
	set sys(geomanager,all) [list pack place grid]

	# a list of all supported geometry managers
	set sys(geomanager,supported) [list pack]

	# a list of ttk widgets that is used to optain validation data
	set sys(widgets,ttk) [list ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::label ttk::labelframe ttk::menubutton ttk::notebook ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator ttk::sizegrip ttk::spinbox ttk::treeview]

	# a list of tk widgets that is used to obtain validation data
	set sys(widgets,default) [list button canvas checkbutton entry frame label labelframe listbox menu menubutton message panedwindow radiobutton scale scrollbar spinbox text]

	# a dict containing widget option validation data after
	# obtainValidationData has been called
	set sys(validation,widget,options) [dict create]

	# a dict containing geometry manager validation data.
	# unline validation,widget,options, this dict is constructed
	# manually
	dict set sys(validation,geomanager,options) pack [list -after -anchor -expand -fill -in -ipadx -ipady -padx -pady -side -before]

	proc load {file} {
		variable sys
		if {![file exists $file]} {
			error "File not found: $file"
		}
		set sys(generate,code) [dict create];# reset generated code

		set data [read [set fl [open $file r]]];close $fl
		dom setStoreLineColumn true
		set doc [dom parse $data]
		
		set xtkElement [$doc getElementsByTagName "xtk"]

		set namespace [initNamespace $xtkElement]
		set sys(ttk) [initTtk $xtkElement]

		traverseTree . 0 $namespace $xtkElement 
		return [generateCode]
	}

	proc run {data} {
		uplevel #0 eval $data
	}

	proc generateCode {} {
		variable sys
		set code "# THIS FILE HAS BEEN AUTOGENERATED BY XTk $sys(meta,version)\n"
		foreach namespace [dict get $sys(generate,code) "namespace"] {
			append code "namespace eval $namespace {\n"
			if {[dict exists $sys(generate,code) ${namespace}_variables]} {
				append code "\n\t# Variable / widget path declaration\n"
				foreach {var value} [dict get $sys(generate,code) ${namespace}_variables] {
					append code "\tset $var $value\n"
				}
			}
			if {[dict exists $sys(generate,code) ${namespace}_commands]} {
				append code "\n\t# GUI Code\n"
				foreach {command} [dict get $sys(generate,code) ${namespace}_commands] {
					append code "\t$command\n"
				}
			}
			append code "}\n"
		}
		return $code
	}

	proc addCommand {namespace command} {
		variable sys
		addNamespaceToCode $namespace
		dict lappend sys(generate,code) ${namespace}_commands $command
	}

	proc addVariable {namespace variableName value} {
		variable sys
		addNamespaceToCode $namespace
		dict lappend sys(generate,code) ${namespace}_variables $variableName $value
	}

	proc doesNamespaceExistInCode {namespace} {
		variable sys
		if {[dict exists $sys(generate,code) "namespace"]} {
			return [in $namespace [dict get $sys(generate,code) "namespace"]]
		} else {
			return 0
		}
	}

	proc addNamespaceToCode {namespace} {
		variable sys
		if {![doesNamespaceExistInCode $namespace]} {
			dict lappend sys(generate,code) "namespace" $namespace
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

	proc traverseTree {currentPath hierarchielevel namespace element} {
		variable sys

		foreach child [$element childNodes] {

			set nodeName [$child nodeName]
			set originalNodeName $nodeName
			if {$sys(ttk)} {
				set nodeName ttk::${nodeName}
			}

			if {[isGeometryManager $originalNodeName]} {
				if {![isGeometryManagerSupported $originalNodeName]} {
					throwNodeErrorMessage $child "sorry, the '$originalNodeName' geometry manager is not yet supported!"
				}
				set sys(currentGeomanagerCommand) [getPackOptions $namespace $child]
				traverseTree $currentPath $hierarchielevel $namespace $child
				continue
			} else {
				if {![isWidgetValid $originalNodeName]} {
					throwNodeErrorMessage $child "the widget '$nodeName' does not exist"
				}
				set parent [[$child parentNode] nodeName]
				if {$parent ne "pack"} {
					throwNodeErrorMessage $child "you must surround widget elements with pack elements"
				}
			}

			set path [getUniquePathSegmentForLevel $hierarchielevel $currentPath]

			handleVariableAttribute $namespace $path $child

			set tkCommand [string trim "${nodeName} $path [getOptionsFromAttributes $namespace $child]"]
			addCommand $namespace "[packTkCommand $sys(currentGeomanagerCommand) $tkCommand]"

			# recursive -> nesting
			if {$originalNodeName eq "frame"} {
				traverseTree $path [expr {$hierarchielevel + 1}] $namespace $child
			}
		}	
	}

	proc isPack {element} {
		set nodeName [$element nodeName]
		return [expr {$nodeName eq "pack"}]
	}

	proc getPackOptions {namespace element} {
		return [getOptionsFromAttributes $namespace $element]
	}

	proc packTkCommand {packOptions tkCommand} {
		return "pack \[$tkCommand\] $packOptions"
	}

	proc handleVariableAttribute {namespace path element} {
		if {[hasVariableAttribute $element]} {
			set variable [getVariableAttribute $element]
			addVariable $namespace $variable $path
		}
	}

	proc hasVariableAttribute {element} {
		return [$element hasAttribute "variable"]
	}

	proc getVariableAttribute {element} {
		return [$element getAttribute "variable"]
	}

	proc getOptionsFromAttributes {namespace element} {
		set tkAttributes [list]
		set tkAttributeValues [list]

		foreach attribute [$element attributes] {
			if {$attribute eq "variable"} {
				continue
			} else {
				set widget [$element nodeName]
				set attr -${attribute}
				if {[isGeometryManager $widget]} {
					if {![isOptionValidForGeometryManager $widget $attr]} {
						throwNodeErrorMessage $element "option '$attribute' not supported for geometrymanager '$widget'"
					}
				} else {
					if {![isOptionValidForWidget $widget $attr]} {
						throwNodeErrorMessage $element "option '$attribute' not supported for widget '$widget'"
					}
				}
				lappend tkAttributes $attr
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
		if {$sys(ttk)} { set widget ttk::${widget} }
		return [dict exists $sys(validation,widget,options) $widget]
	}

	proc isOptionValidForWidget {widget option} {
		variable sys
		if {$sys(ttk)} { set widget ttk::${widget} }
		return [in $option [dict get $sys(validation,widget,options) $widget]]
	}
	
	proc isGeometryManager {geomanager} {
		variable sys
		return [in $geomanager $sys(geomanager,all)]
	}

	proc isGeometryManagerSupported {geomanager} {
		variable sys
		return [in $geomanager $sys(geomanager,supported)]
	}

	proc isOptionValidForGeometryManager {geomanager option} {
		variable sys
		return [in $option [dict get $sys(validation,geomanager,options) $geomanager]]
	}

	obtainValidationData

	namespace export run load
}
