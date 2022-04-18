module main

import term

const (
	errno_no_toml_config     = 0x001001
	errno_toml_parse_failure = 0x001002

	errors                   = {
		errno_no_toml_config:     'No config.toml file found. Attempted to create with default values resulting in failure. Please check that this program has read/write persmissions. Exiting with code $errno_no_toml_config .'
		errno_toml_parse_failure: 'Failed to parse config.toml. This could either be because this program does not have read permissions or the file may be corrupted/incorectly formatted. Exiting with code $errno_toml_parse_failure .'
	}
)

// println_error prints provided text to the terminal with
// "Error: " prefixed in red text.
fn println_error(str string) {
	println(term.rgb(230, 20, 70, 'Error: ') + str)
}

// println_error prints provided text to the terminal with
// "Warning: " prefixed in orange text.
fn println_warning(str string) {
	println(term.rgb(230, 115, 40, 'Warning: ') + str)
}

// println_error prints provided text to the terminal with
// "Notice: " prefixed in yellow text.
fn println_notice(str string) {
	println(term.rgb(230, 230, 40, 'Notice: ') + str)
}
