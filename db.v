module main

import mysql

const(
	const_mysql_host_address = '127.0.0.1'
	const_mysql_host_port = 3306
	const_mysql_username = ''
	const_mysql_password = ''
	const_mysql_database = 'pandassist'
	const_mysql_void_connection = mysql.Connection{
		host: '0.0.0.0'
		port: 0
	}
)

const(
	const_mysql_error_username_taken = error('Selected username is already in use.')
	const_mysql_error_email_taken = error('Selected email address is already in use.')
)

fn new_connection() mysql.Connection {
	mut conn := mysql.Connection{
		host: const_mysql_host_address
		port: u32(const_mysql_host_port)
		username: const_mysql_username
		password: const_mysql_password
		dbname: const_mysql_database
	}
	return conn
}