module main

import os
import toml

const(
	const_config_path = './config.toml'
	const_default_conf = 
	'
	port = 80
	
	[mysql]
	dbname = "pandassist"
	host = "127.0.0.1"
	port = 3306
	username = ""
	password = ""
	'
)

fn parse_toml(path string) toml.Doc {
	if !os.exists(const_config_path) {
		os.write_file(const_config_path, const_default_conf) or {
			println_error(errors[errno_no_toml_config])
			exit(0)
		}
	}
	doc := toml.parse_file(path) or {
		println_error(errors[errno_no_toml_config])
		exit(0)
	}
	return doc
}