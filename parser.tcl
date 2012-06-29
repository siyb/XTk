package provide XTkParser 0.2

package require tdom

namespace import oo::*
namespace import ::tcl::mathop::*

class create Parser {
	method load {file} {
		variable sys
		if {![file exists $file]} {
			error "File not found: $file"
		}

		set data [read [set fl [open $file r]]];close $fl
		return [xml2tk $data]
	}

	method xml2tk {xml} {
		my variable code
		
		dom setStoreLineColumn true
		
		set doc [dom parse $xml]
		set xtkElement [$doc getElementsByTagName "xtk"]

		set namespace [initNamespace $xtkElement]
		set sys(ttk) [initTtk $xtkElement]
		traverseTree . 0 $namespace $xtkElement
		return [$code]
	}
	
	method parse {element} {
		foreach child [$element childNodes] {
			set nodeName [$child nodeName]
		}
	}
	
	method handleWidgetCommand {element} {
	}
	
	method handleGeometryManager {element} {
	}
	
	method handleImageTag {element} {
	}
}

class create WidgetInformation {
	variable sys validationData
	
	constructor {} {
		# a list of ttk widgets that is used to optain validation data
		set sys(widgets,ttk) [list ttk::button ttk::checkbutton ttk::combobox ttk::entry ttk::frame ttk::label ttk::labelframe ttk::menubutton ttk::notebook ttk::panedwindow ttk::progressbar ttk::radiobutton ttk::scale ttk::scrollbar ttk::separator ttk::sizegrip ttk::spinbox ttk::treeview]
		# a list of tk widgets that is used to obtain validation data
		set sys(widgets,default) [list button checkbutton entry frame label labelframe menu menubutton message panedwindow radiobutton scale scrollbar spinbox]
		# a list of tk widgets that have no ttk equivalent
		set sys(widgets,nottk) [list canvas listbox menu message text toplevel]
		# a list to store the validation data
		set validationData [list]
		
		# create validation data
		my obtainValidationData
	}
	
	destructor {} {
		foreach item $validationData {
			$item destroy
		}
	}
	
	method obtainValidationData {} {
		set counter 0
		foreach {key widgets} [array get sys widgets,*] {
			foreach widget $widgets {
				if {[catch {
					$widget .${counter}
					set options [.${counter} configure]
					set supportedWidgetOptions [my getAvailableOptionsFromOptionList $options]
					destroy .${counter}
					incr counter
					my addWidgetValidationData $widget $supportedWidgetOptions
				} err]} {
					puts "could not obtain configuration data for $widget: $::errorInfo"
				}
			}
		}
	}
	
	method getAvailableOptionsFromOptionList {optionList} {
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
	
	method addWidgetValidationData {widget supportedWidgetOptions} {
		lappend validationDate [ValidationData new $widget $supportedWidgetOptions]
	}
	
	method isWidgetValid {widget} {
		foreach widgetData $validationData {
			if {[$widgetData getWidget] eq $widget} {
				return 1
			}
		}
		return 0
	}
	
	method isOptionValidForWidget {option widget} {
		foreach widgetData $validationData {
			if {[$widgetData getWidget] eq $widget} {
				return [in [$widgetData getOptions] $option]
			}
		}
		return 0
	}

}

class create ValidationData {
	variable widget supportedWidgetOptions
	
	constructor {_widget _supportedWidgetOptions} {
		set widget $_widget
		set supportedWidgetOptions $_supportedWidgetOptions
	}

	method getWidget {} {
		return $widget
	}
	
	method getSupportedWidgetOptions {} {
		return $supportedWidgetOptions
	}
}