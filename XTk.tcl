package provide XTk 0.1

package require Tk
package require tdom
namespace eval xtk {
	namespace import ::tcl::mathop::*
	variable sys

	if {[catch { package require base64 } err]} {
		puts "*** warn *** base64 could not be found, you may not encode images using base64!"
		set sys(base64) 0
	} else {
		set sys(base64) 1
	}


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
	# unlike validation,widget,options, this dict is constructed
	# manually
	dict set sys(validation,geomanager,options) pack [list -after -anchor -expand -fill -in -ipadx -ipady -padx -pady -side -before]

	# a dict containing image validation data
	dict set sys(validation,image,options) photo [list -data -format -file -gamma -height -palette -width]
	dict set sys(validation,image,options) bitmap [list -background -data -file -foreground -maskdata -maskfile]

	proc load {file} {
		variable sys
		if {![file exists $file]} {
			error "File not found: $file"
		}

		set data [read [set fl [open $file r]]];close $fl
		return [xml2tk $data]
	}

	proc xml2tk {xml} {
		variable sys
		set sys(generate,code) [dict create];# reset generated code
		
		dom setStoreLineColumn true
		set doc [dom parse $xml]
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
		set base64code "# THIS FILE HAS BEEN AUTOGENERATED BY XTk $sys(meta,version)\n"
		set code ""
		foreach namespace [dict get $sys(generate,code) "namespace"] {
			append code "namespace eval $namespace {\n"
			if {[dict exists $sys(generate,code) ${namespace}_images]} {
				append code "\n\t# Image declaration\n"
				append code "\tnamespace eval images {\n"
				append base64code "\nnamespace eval ${namespace}::images {\n"
				foreach {namespace type options variable base64} [dict get $sys(generate,code) ${namespace}_images] {
					if {$base64 && $sys(base64)} {
						set base64Data [base64Encode [dict get $options "-file"]]
						append base64code "\t\tset base64(${variable}) \"$base64Data\"\n"
						set options [dict remove $options "-file"]
						dict set options -data $${namespace}::images::base64(${variable})
						append code "\t\tset $variable \[image create $type [join $options]]\n"
					} else {
						append code "\t\tset $variable \[image create $type $options]\n"
					}
				}
				append base64code "}\n"
				append code "\t}\n"
			}
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
			if {[dict exists $sys(generate,code) ${namespace}_binds]} {
				append code "\n\t# GUI Bindings\n"
				foreach {path evnt virtual callbackString} [dict get $sys(generate,code) ${namespace}_binds] {
					if {$virtual} {
						set evnt "<<$evnt>>"
					} else {
						set evnt "<$evnt>"
					}
					append code "\tbind $path $evnt { ${namespace}::bindCallback $path $callbackString }\n"
				}
			}
			append code "}\n\n"
			set ret ${base64code}${code}
		}
		return $ret
	}

	proc base64Encode {file} {
		if {$file == ""} { return }
		set fileID [open $file RDONLY]
		fconfigure $fileID -translation binary
		set rawData [read $fileID]
		close $fileID
		set encodedData [base64::encode $rawData]
		return $encodedData
	}


	proc addCommand {namespace command} {
		variable sys
		addNamespaceToCode $namespace
		dict lappend sys(generate,code) ${namespace}_commands $command
	}

	proc addBind {namespace path event virtual callbackString} {
		variable sys
		addNamespaceToCode $namespace
		dict lappend sys(generate,code) ${namespace}_binds $path $event $virtual $callbackString
	}

	proc addVariable {namespace variableName value} {
		variable sys
		addNamespaceToCode $namespace
		dict lappend sys(generate,code) ${namespace}_variables $variableName $value
	}

	proc addImage {namespace type options variable {base64 0}} {
		variable sys
		addNamespaceToCode $namespace
		dict lappend sys(generate,code) ${namespace}_images $namespace $type $options $variable $base64
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
		if {![hasNamespaceAttribute $xtkElement]} {
			throwNodeErrorMessage $xtkElement "The namespace attribute must be provided for the xtk element"
		}
		set namespace [getNamespaceAttribute $xtkElement]
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
				if {[hasBindCommand $element]} {
					throwNodeErrorMessage $child "bind may not be a child of any geometry manager node"
				}
				set sys(currentGeomanagerCommand) [getPackOptions $namespace $child]

				traverseTree $currentPath $hierarchielevel $namespace $child
				continue
			} elseif {[isImageCommand $child]} {
				if {![hasTypeAttribute $child]} {
					throwNodeErrorMessage $child "no type attribute has been specified"
				}
				if {![hasVariableAttribute $child]} {
					throwNodeErrorMessage $child "missing variable declaration"
				}
				if {![isVariableAttributeValid $child]} {
					throwNodeErrorMessage $child "variable attribute may not be empty"
				}
				set base64 0
				if {[hasBase64Attribute $child]} {
					set base64 [getBase64Attribute $child]
					if {![isBoolean $base64]} {
						throwNodeErrorMessage $child "base64 attribute is not boolean: ${base64}"
					}
				}
				set variable [getVariableAttribute $child]
				set type [getTypeAttribute $child]
				if {$type eq ""} {
					throwNodeErrorMessage $child "type may not be empty"
				}
				set options [getOptionsFromAttributes $namespace $child]
				if {$base64 && ([lsearch $options "-file"] == -1 || [lsearch $options "-data"] != -1)} {
					throwNodeErrorMessage $child "base64 was provided, you MUST provide the -file attribute and MUST NOT provide the -data attribute"
				}
				addImage $namespace $type $options $variable $base64
				continue
			} elseif {[isWidgetValid $originalNodeName]} {
				set parent [$child parentNode]
				if {![isPack $parent]} {
					throwNodeErrorMessage $child "you must surround widget elements with pack elements '$originalNodeName'"
				}
			} else {
				throwNodeErrorMessage $child "unknown element '$nodeName'"
			}

			set path [getUniquePathSegmentForLevel $hierarchielevel $currentPath]

			handleBindCommand $namespace $path $child
			handleVariableAttributeWidget $namespace $path $child

			set tkCommand [string trim "${nodeName} $path [getOptionsFromAttributes $namespace $child]"]
			addCommand $namespace "[packTkCommand $sys(currentGeomanagerCommand) $tkCommand]"

			# recursive -> nesting
			if {$originalNodeName eq "frame"} {
				traverseTree $path [expr {$hierarchielevel + 1}] $namespace $child
			}
		}	
	}

	proc isImageCommand {element} {
		return [eq [$element nodeName] "image"]
	}

	proc hasTypeAttribute {element} {
		return [$element hasAttribute "type"]
	}

	proc getTypeAttribute {element} {
		return [$element getAttribute "type"]
	}

	proc hasBase64Attribute {element} {
		return [$element hasAttribute "base64"]
	}

	proc getBase64Attribute {element} {
		return [$element getAttribute "base64"]
	}

	proc isBoolean {value} {
		return [| [eq $value 1] [eq $value 0]]
	}

	proc hasNamespaceAttribute {element} {
		return [$element hasAttribute "namespace"]
	}

	proc getNamespaceAttribute {element} {
		return [$element getAttribute "namespace"]
	}

	proc handleBindCommand {namespace path child} {
		if {[hasBindCommand $child]} {
			set bindCommands [getBindCommands $child]
			foreach bindCommand $bindCommands {
				if {![hasEvent $bindCommand]} {
					throwNodeErrorMessage $bindCommand "you need to provide the event attribute"
				}
				if {![hasVirtual $bindCommand]} {
					throwNodeErrorMessage $bindCommand "you need to provide the virtual attribute"
				}
				set evnt [getEvent $bindCommand]
				if {$evnt eq ""} {
					throwNodeErrorMessage $bindCommand "event may not be empty"
				}
				set callbackString [$bindCommand getAttribute "callbackString" ""]
				set virtual [$bindCommand getAttribute "virtual"]
				addBind $namespace $path $evnt $virtual $callbackString
			}
		}

	}

	proc isPack {element} {
		set nodeName [$element nodeName]
		return [eq $nodeName "pack"]
	}

	proc getPackOptions {namespace element} {
		return [getOptionsFromAttributes $namespace $element]
	}

	proc packTkCommand {packOptions tkCommand} {
		return "pack \[$tkCommand\] $packOptions"
	}

	proc handleVariableAttributeWidget {namespace path element} {
		if {[hasVariableAttribute $element]} {
			if {![isVariableAttributeValid $element]} {
				throwNodeErrorMessage $element "variable attribute may not be empty"
			}
			set variable [getVariableAttribute $element]
			addVariable $namespace $variable $path
		}
	}

	proc hasVariableAttribute {element} {
		return [$element hasAttribute "variable"]
	}

	proc isVariableAttributeValid {element} {
		return [ne [getVariableAttribute $element] ""]
	}

	proc getVariableAttribute {element} {
		return [$element getAttribute "variable"]
	}

	proc hasBindCommand {element} {
		foreach childNode [$element childNodes] {
			if {[$childNode nodeName] eq "bind"} {
				return 1
			}
		}
		return 0
	}

	proc getBindCommands {element} {
		return [$element getElementsByTagName "bind"]
	}

	proc hasVirtual {element} {
		return [$element hasAttribute "virtual"]
	}

	proc isVirtual {element} {
		set virtual [$element getAttribute "virtual"]
		if {![isBoolean $virtual]} {
			throwNodeErrorMessage $element "virtual must be 1 or 0"
		}
		return $virtual
	}

	proc hasEvent {element} {
		return [$element hasAttribute "event"]
	}

	proc getEvent {element} {
		return [$element getAttribute "event"]
	}

	proc getOptionsFromAttributes {namespace element} {
		set tkAttributes [list]
		set tkAttributeValues [list]

		foreach attribute [$element attributes] {
			# variable attribute, virutal, valid for many tags
			if {$attribute eq "variable"} {
				continue
			# image specific virual attributes
			} elseif {$attribute eq "type" || $attribute eq "base64"} {
				continue
			} else {
				set widget [$element nodeName]
				set attr -${attribute}
				if {[isGeometryManager $widget]} {
					if {![isOptionValidForGeometryManager $widget $attr]} {
						throwNodeErrorMessage $element "option '$attribute' not supported by geometrymanager '$widget'"
					}
				} elseif {[isImageCommand $element]} {
					if {![isOptionValidForImage [getTypeAttribute $element] $attr]} {
						throwNodeErrorMessage $element "option '$attribute' not supported by image '$widget'" 
					}
				} else {
					if {![isOptionValidForWidget $widget $attr]} {
						throwNodeErrorMessage $element "option '$attribute' not supported by widget '$widget'"
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
		set ret [list]
		foreach option $tkAttributes value $tkAttributeValues {
			if {[llength $value] > 1} {
				set value \"$value\"
			}
			append ret "$option $value "
		}
		set ret [string trim $ret]
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

	proc isOptionValidForImage {type option} {
		variable sys
		if {![dict exists $sys(validation,image,options) $type]} {
			puts "*** warn *** no validation possible: $type"
			return 1
		}
		return [in $option [dict get $sys(validation,image,options) $type]]
	}

	obtainValidationData

	namespace export run load xml2tk
}
