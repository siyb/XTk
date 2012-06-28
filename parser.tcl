package provide XTkParser 0.2

package require tdom

namespace import oo::*

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