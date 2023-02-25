module main

import db.mysql
import nedpals.vex.session
import time
import toml

const (
	const_mysql_void_connection = mysql.Connection{
		host: '0.0.0.0'
		port: 0
	}
	const_mysql_username_max_len = 30
	const_mysql_name_max_len     = 80
	const_mysql_email_max_len    = 100
	const_mysql_password_max_len = 100
	const_mysql_phone_max_len    = 31
)

const (
	const_mysql_error_username_taken     = error('Selected username is already in use.')
	const_mysql_error_email_taken        = error('Selected email address is already in use.')
	const_mysql_error_username_gt_max    = error('Selected username exceeds character limit of $const_mysql_username_max_len .')
	const_mysql_error_name_gt_max        = error('Full name provided exceeds character limit of $const_mysql_name_max_len .')
	const_mysql_error_email_gt_max       = error('Selected email exceeds character limit of $const_mysql_email_max_len .')
	const_mysql_error_password_gt_max    = error('Password provided exceeds character limit of $const_mysql_password_max_len .')
	const_mysql_error_phone_gt_max       = error('Phone number provided exceeds character limit of $const_mysql_phone_max_len .')

	const_mysql_error_teacher_not_found  = error('No entry found in table `teachers` with matching id.')
	const_mysql_error_students_not_found = error('No entries found in table `students` with matching ids.')
	const_mysql_error_events_not_found = error('No entries found in table `event` with matching ids.')
)

// new_connection returns a new MySQL connection to the database
// found in config.toml
fn new_connection(config toml.Doc) mysql.Connection {
	return mysql.Connection{
		dbname: config.value('mysql.dbname').default_to('panda').string()
		host: config.value('mysql.host').default_to('127.0.0.1').string()
		port: u32(config.value('mysql.port').default_to(3306).int())
		username: config.value('mysql.username').default_to('').string()
		password: config.value('mysql.password').default_to('').string()
	}
}

// register_user validates the fields provided in `data`. If
// everything checks out, then user information is inserted
// into database.
fn (app &App) register_user(data map[string]string) ? {
	mut conn := new_connection(app.config)
	conn.connect() ?
	defer {
		conn.close()
	}

	// see db.v for values of const's
	if data['username'].len > const_mysql_username_max_len {
		return const_mysql_error_username_gt_max
	}
	if data['name'].len > const_mysql_name_max_len {
		return const_mysql_error_name_gt_max
	}
	if data['email'].len > const_mysql_email_max_len {
		return const_mysql_error_email_gt_max
	}
	if data['password'].len > const_mysql_password_max_len {
		return const_mysql_error_password_gt_max
	}
	if data['phone'].len > const_mysql_phone_max_len {
		return const_mysql_error_phone_gt_max
	}

	// Check if username is taken. Two people cannot possibly
	// be in possession of the same username.
	query_username_taken := "SELECT * FROM teachers WHERE username='" + data['username'] + "';"
	result_username_taken := conn.query(query_username_taken) ?
	if result_username_taken.n_rows() > 0 {
		return const_mysql_error_username_taken
	}

	// Check if email is taken.
	query_email_taken := "SELECT * FROM teachers WHERE email='" + data['email'] + "';"
	result_email_taken := conn.query(query_email_taken) ?
	if result_email_taken.n_rows() > 0 {
		return const_mysql_error_email_taken
	}

	dob := time.sys_mono_now()
	query_insert :=
		"INSERT INTO teachers (username, name, email, password, phone, dob) VALUES ('" +
		data['username'] + "', '" + data['name'] + "', '" + data['email'] + "', '" +
		data['password'] + "', '" + data['phone'] + "', " + dob.str() + ');'
	result_insert := conn.query(query_insert) ?
	if conn.affected_rows() == 0 {
		return error('Failed to insert user into database. ' + result_insert.str())
	}
}

// get_id_from_email connects to the database and fetches the id
// of the row with the provided email
fn (app &App) get_id_from_email(email string) ?int {
	mut conn := new_connection(app.config)
	conn.connect() ?
	// closing the database is causing a RUNITIME ERROR: abort()
	defer { conn.close() }

	query := 'SELECT id FROM teachers WHERE email=\'$email\';'
	res := conn.query(query) ?
	return if res.n_rows() == 0 {
		const_mysql_error_teacher_not_found
	} else {
		res.maps()[0]['id'].int()
	}
}

// get_teacher creates a Teacher object from the provided id
fn (app &App) get_teacher(ses session.Session) ?Teacher {
	mut id := ses.get('id').int()
	if id == 0 {
		id = app.get_id_from_email(ses.get('email')) ?
	}

	mut conn := new_connection(app.config)
	conn.connect() ?
	defer {
		conn.close()
	}

	query := 'SELECT * FROM teachers WHERE id=$id;'
	res := conn.query(query) ?
	if res.n_rows() == 0 {
		return const_mysql_error_teacher_not_found
	}

	row := res.maps()[0]
	
	// ids of students
	ids_str := row['students'].split(',')
	mut ids := []int{cap: ids_str.len}
	for i in ids_str {
		ids << i.trim_space().int()
	}
	
	// ids of events
	evt_ids_str := row['events'].split(',')
	mut evt_ids := []int{cap: evt_ids_str.len}
	for i in evt_ids_str {
		evt_ids << i.trim_space().int()
	}
	
	return Teacher{
		id: row['id'].u64()
		username: row['username']
		name: row['full_name']
		email: row['email']
		dob: time.unix(row['account_birth'].i64())
		phone: row['phone']
		students: app.get_students(ids) or {
			println(err.msg())
			[]Student{}
		}
		events: app.get_events(evt_ids) or {
			println(err.msg())
			[]Event{}
		}
	}
}

fn (app &App) get_events(ids []int) ?[]Event {
	mut conn := new_connection(app.config)
	conn.connect() ?
	defer {
		conn.close()
	}
	
	if ids.len <= 0 {
		return none
	}
	
	mut query := 'SELECT * FROM events WHERE id IN (' + ids[0].str()
	if ids.len > 1 {
		for i := 1; i < ids.len; i++ {
			query += ', ' + ids[i].str()
		}
	}
	query += ') ORDER BY time ASC;'
	
	res := conn.query(query) ?
	if res.n_rows() == 0 {
		return const_mysql_error_events_not_found
	}
	
	mut events := []Event{cap: int(res.n_rows())}
	for row in res.maps() {
		events << Event{
			id: row['id'].u64()
			description: row['description']
			category: row['category']
			time: time.unix(row['time'].i64())
		}
	}
	return events
}

// get_students returns an array of Student from the provided ids
fn (app &App) get_students(ids []int) ?[]Student {
	mut conn := new_connection(app.config)
	conn.connect() ?
	defer {
		conn.close()
	}

	if ids.len <= 0 {
		return none
	}

	mut query := 'SELECT * FROM students WHERE id IN (' + ids[0].str()
	if ids.len > 1 {
		for i := 1; i < ids.len; i++ {
			query += ', ' + ids[i].str()
		}
	}
	query += ') ORDER BY name;'

	res := conn.query(query) ?
	if res.n_rows() == 0 {
		return const_mysql_error_students_not_found
	}

	mut students := []Student{cap: int(res.n_rows())}
	for row in res.maps() {
		students << Student{
			id: row['id'].u64()
			name: row['name']
			gender: unsafe { Gender(row['gender'].int()) }
			avatar_path: row['avatar_path']
		}
	}
	return students
}
