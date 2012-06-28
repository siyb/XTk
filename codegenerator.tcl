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
	set commands [list]
	set variables [list]
	set binds [list]
	set images [list]
	
	constructor {_namespace} {
		my variable namespace
		set namespace $_namespace
	}
	
	method addCommand {command} {
		my variable commands
		lappend commands $commands
	}
	
	method addVariable {variable} {
		my variable variables
		lappend variables $variable
	}
	
	method addBind {bind} {
		my variable binds
		lappend binds $bind
	}
	
	method addImage {image} {
		my variable images
		lappend images $image
	}
	
	method getCommands {} {
		my variable commands
		return $commands
	}
	
	method getVariables {} {
		my variable variables
		return $variables
	}
	
	method getBinds {} {
		my variable binds
		return $binds
	}
}

class create Command {
	constructor {_command} {
		my variable command
		set command $_command
	}
	
	method getCommand {} {
		my variable command
		return $command
	}
}

class create Variable {
	constructor {_varName _value} {
		my variable varName
		my variable value
		set varName $_varName
		set value $v_alue
	}
	
	method getVarName {} {
		my variable varName
		return $varName
	}
	
	method getValue {} {
		my variable value
		return $value
	}
}

class create Bind {
	constructor {_path _evnt _virtual _callbackString} {
		my variable path
		my variable evnt
		my variable virtual
		my variable callbackString
		set path $_path
		set evnt $_evnt
		set virtual $_virtual
		set callbackString $_callbackString
	}
	
	method getPath {} {
		my variable path
		return $path
	}
	
	method getEvnt {} {
		my variable evnt
		return $evnt
	}
	
	method getVirtual {} {
		my variable virtual
		return $virtual
	}
	
	method getCallbackString {} {
		my variable callbackString
		return $callbackString
	}
}

class create Image {
	constructor {_type _options _variable _base64} {
		my variable type
		my variable options
		my variable variable
		my variable base64
		set type $_type
		set options $_options
		set variable$_variable
		set callbackString $_base64
	}
	
	method getType {} {
		my variable type
		return $type
	}
	
	method getOptions {} {
		my variable options
		return $options
	}
	
	method getVariable {} {
		my variable variable
		return $variable
	}
	
	method getBase64 {} {
		my variable base64
		return $base64
	}
}