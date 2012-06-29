package provide 0.2

namespace import oo::*

class create CodeGenerator {

	constructor {_code} {
		my variable code $_code
	}
	
	method generateCode {} {
		my variable code
		my variable codeString
		set namespace [$code getNamespace]
		
		append code "namespace eval $namespace {\n"
		append code "\n\t# Image declaration\n"
		append code "\tnamespace eval images {\n"
		foreach image [$code getImages] {
			set options [$image getOptions]
			set variable [$image getVariable]
			set type [$image getType]
			if {[$image getBase64]} {
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
		
		append code "\n\t# Variable / widget path declaration\n"
		foreach variable [$code getVariables] {
		}
		
		append code "\n\t# GUI Code\n"
		foreach command [$code getCommands] {
			append code "\t[$command getCommand]\n"
		}
		
		append code "\n\t# GUI Bindings\n"
		foreach bind [$code getBinds] {
			if {$virtual} {
				set evnt "<<[$bind getEvnt]>>"
			} else {
				set evnt "<[$bind getEvnt]>"
			}
			append code "\tbind [$bind getPath] $evnt { ${namespace}::bindCallback [$bind getPath] [$bind getCallbackString] }\n"
		}
	}
}

class create Code {
	variable commands
	variable variables
	variable binds
	variable images
	variable namespace
	
	constructor {_namespace} {
		set namespace $_namespace
		set commands [list]
		set variables [list]
		set binds [list]
		set images [list]
	}
	
	method addCommand {command} {
		lappend commands $commands
	}
	
	method addVariable {variable} {
		lappend variables $variable
	}
	
	method addBind {bind} {
		lappend binds $bind
	}
	
	method addImage {image} {
		lappend images $image
	}
	
	method getCommands {} {
		return $commands
	}
	
	method getVariables {} {
		return $variables
	}
	
	method getBinds {} {
		return $binds
	}
}

class create Command {
	variable command
	
	constructor {_command} {
		set command $_command
	}
	
	method getCommand {} {
		return $command
	}
}

class create Variable {
	variable varName
	variable value
	
	constructor {_varName _value} {
		set varName $_varName
		set value $v_alue
	}
	
	method getVarName {} {
		return $varName
	}
	
	method getValue {} {
		return $value
	}
}

class create Bind {
	variable path
	variable evnt
	variable virtual
	variable callbackString
	
	constructor {_path _evnt _virtual _callbackString} {
		set path $_path
		set evnt $_evnt
		set virtual $_virtual
		set callbackString $_callbackString
	}
	
	method getPath {} {
		return $path
	}
	
	method getEvnt {} {
		return $evnt
	}
	
	method getVirtual {} {
		return $virtual
	}
	
	method getCallbackString {} {
		return $callbackString
	}
}

class create Image {
	variable type
	variable options
	variable variable
	variable base64
	
	constructor {_type _options _variable _base64} {
		set type $_type
		set options $_options
		set variable$_variable
		set callbackString $_base64
	}
	
	method getType {} {
		return $type
	}
	
	method getOptions {} {
		return $options
	}
	
	method getVariable {} {
		return $variable
	}
	
	method getBase64 {} {
		return $base64
	}
}