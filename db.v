module main

import mysql
import toml

const(
	const_mysql_void_connection = mysql.Connection{
		host: '0.0.0.0'
		port: 0
	}
	const_mysql_username_max_len = 30
	const_mysql_name_max_len = 80
	const_mysql_email_max_len = 100
	const_mysql_password_max_len = 100
	const_mysql_phone_max_len = 31
)

const(
	const_mysql_error_username_taken = error('Selected username is already in use.')
	const_mysql_error_email_taken = error('Selected email address is already in use.')
	const_mysql_error_username_gt_max = error('Selected username exceeds character limit of $const_mysql_username_max_len .')
	const_mysql_error_name_gt_max = error('Full name provided exceeds character limit of $const_mysql_name_max_len .')
	const_mysql_error_email_gt_max = error('Selected email exceeds character limit of $const_mysql_email_max_len .')
	const_mysql_error_password_gt_max = error('Password provided exceeds character limit of $const_mysql_password_max_len .')
	const_mysql_error_phone_gt_max = error('Phone number provided exceeds character limit of $const_mysql_phone_max_len .')
)

fn new_connection(config toml.Doc) mysql.Connection {
	return mysql.Connection{
		dbname: config.value('mysql.dbname').default_to('panda').string()
		host: config.value('mysql.host').default_to('127.0.0.1').string()
		port: u32(config.value('mysql.port').default_to(3306).int())
		username: config.value('mysql.username').default_to('').string()
		password: config.value('mysql.password').default_to('').string()
	}
}