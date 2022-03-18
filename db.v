module main

import mysql
import toml

const(
	const_mysql_void_connection = mysql.Connection{
		host: '0.0.0.0'
		port: 0
	}
)

const(
	const_mysql_error_username_taken = error('Selected username is already in use.')
	const_mysql_error_email_taken = error('Selected email address is already in use.')
)

fn new_connection(config toml.Doc) mysql.Connection {
	mut conn := mysql.Connection{
		dbname: config.value('mysql.dbname').default_to('panda').string()
		host: config.value('mysql.host').default_to('127.0.0.1').string()
		port: u32(config.value('mysql.port').default_to(3306).int())
		username: config.value('mysql.username').string()
		password: config.value('mysql.password').string()
	}
	return conn
}