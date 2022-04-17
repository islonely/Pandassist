module main

import crypto.bcrypt
import os
import time
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

// parse_toml reads the toml file at the provided path if it exists
// and parses the contents.
fn parse_toml(path string) toml.Doc {
	if !os.exists(path) || !os.is_file(path) {
		os.write_file(path, const_default_conf) or {
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

// calc_ideal_bcrypt_cost automatically determines what the optimal cost for the
// bcrypt algorithm should be. This scales with hardware. So as processors get more
// efficient, the higher the return integer will be. Returns `bcrypt.default_cost` on error.
fn calc_ideal_bcrypt_cost() int {
	mut cost := 1
	mut sw := time.new_stopwatch()
	sw.start()
	hash := bcrypt.generate_from_password('microbenchmark'.bytes(), cost) or {''}
	sw.stop()
	if hash == '' { return bcrypt.default_cost }
	
	mut duration_ms := sw.elapsed().milliseconds()
	for duration_ms < 250 {
		cost++
		duration_ms *= 2
	}
	// for security purposes you should never use cost lower than default
	// regardless of what is generated
	if cost < bcrypt.default_cost {
		cost = bcrypt.default_cost
	}
	return cost
}