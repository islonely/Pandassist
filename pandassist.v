module main

import crypto.bcrypt
import htmlbuilder
import json
import mysql
import nedpals.vex.ctx
import nedpals.vex.router
import nedpals.vex.server
import nedpals.vex.session
import os
import time
import toml

// App is an extension of Router from the nedpals.vex module.
struct App {
mut:
	config toml.Doc
	dbconn mysql.Connection
	html_components map[string]string
}

// JsonResponse is the the response sent back upon post request.
// Mainly to send back to a jQuery $.ajax request.
struct JsonResponse {
	message string
	error   bool
}

// str returns JsonResponse as a JSON encoded string.
fn (jr JsonResponse) str() string {
	return json.encode(jr)
}

fn main() {
	mut app := App{
		config: parse_toml(const_config_path)
		html_components: {
			'navbar': htmlbuilder.navbar
		}
	}
	app.dbconn = new_connection(app.config)

	// serves files in the assets directory on the specified path
	route_assets := fn (req &ctx.Req, mut res ctx.Resp) {
		res.send_file('./assets/' + req.params['path'], 200)
	}

	route_calendar := fn [mut app] (req &ctx.Req, mut res ctx.Resp) {
		mut ses := session.start(req, mut res, secure: true)
		if !ses.has('email') {
			res.redirect('/login')
			return
		}

		mut calendar_html := os.read_file('./html/calendar.html') or {
			res.send('Internal Server Error', 500)
			return
		}
		calendar_html = calendar_html.replace('\$vex_insert_navbar', app.html_components['navbar'])

		mut id := ses.get('id').int()
		if id == 0 {
			id = app.get_id_from_email(ses.get('email')) or {
				// this should never happen since we check for email
				// at the beginning of func.
				res.redirect('/login')
				return
			}
		}

		teacher := app.get_teacher(id) or {
			res.send('Internal Server Error', 500)
			println(err.msg())
			return
		}

		res.send_html(calendar_html, 200)
	}

	route_dashboard := fn [mut app] (req &ctx.Req, mut res ctx.Resp) {
		mut ses := session.start(req, mut res, secure: true)
		if !ses.has('email') {
			res.redirect('/login')
			return
		}

		mut dashboard_html := os.read_file('./html/dashboard.html') or {
			res.send('Internal Server Error', 500)
			return
		}
		dashboard_html = dashboard_html.replace('\$vex_insert_navbar', app.html_components['navbar'])

		mut id := ses.get('id').int()
		if id == 0 {
			id = app.get_id_from_email(ses.get('email')) or {
				// this should never happen since we check for email
				// at the beginning of func.
				res.redirect('/login')
				return
			}
		}

		teacher := app.get_teacher(id) or {
			res.send('Internal Server Error', 500)
			println(err.msg())
			return
		}
		dashboard_html = dashboard_html.replace('\$vex_insert_students', teacher.students.html())

		res.send_html(dashboard_html, 200)
	}

	// route_login serves the login page to the end user
	route_login := fn [mut app] (req &ctx.Req, mut res ctx.Resp) {
		ses := session.start(req, mut res, secure: true)
		if ses.get('logged_in').bool() {
			res.redirect('/dashboard')
			return
		}
		res.send_file('./html/login.html', 200)
	}

	// route_login_post handles post request made to the login
	// route. This will either be a request to login or to
	// register a new user.
	route_login_post := fn [mut app] (req &ctx.Req, mut res ctx.Resp) {
		mut data := req.parse_form() or {
			res.send_json(JsonResponse{
				error: true
				message: 'Failed to parse form data: $err.msg()'
			}, 200)
			return
		}

		mut ses := session.start(req, mut res, secure: true)

		match data['action'] {
			'login' {
				app.dbconn.connect() or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to connect to database. $err.msg()'
					}, 200)
					return
				}
				defer {
					app.dbconn.close()
				}

				query_hashword := "SELECT password FROM teachers WHERE email='" + data['email'] +
					"';"
				result_hashword := app.dbconn.query(query_hashword) or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to query database. $err.msg()'
					}, 200)
					return
				}

				// no user in database with provided email.
				if result_hashword.n_rows() == 0 {
					res.send_json(JsonResponse{
						error: false
						message: 'Incorrect username or password.'
					}, 200)
					return
				}

				hashword := result_hashword.maps()[0]['password']
				bcrypt.compare_hash_and_password(data['password'].bytes(), hashword.bytes()) or {
					res.send_json(JsonResponse{
						error: false
						message: 'Incorrect username or password.'
					}, 200)
					return
				}

				new_hashword := bcrypt.generate_from_password(data['password'].bytes(),
					calc_ideal_bcrypt_cost()) or {
					res.send_json(JsonResponse{
						error: false
						message: 'Notice: Failed to hash new password.'
					}, 200)
					return
				}
				query_update_password := "UPDATE teachers SET password='" + new_hashword +
					"' WHERE email='" + data['email'] + "';"
				app.dbconn.query(query_update_password) or {
					res.send_json(JsonResponse{
						error: false
						message: 'Notice: Failed to insert new password hash.'
					}, 200)
					return
				}

				if app.dbconn.affected_rows() == 0 {
					res.send_json(JsonResponse{
						error: false
						message: 'Notice: Failed to insert new password hash.'
					}, 200)
					return
				}

				ses.set_many('logged_in', 'true', 'email', data['email']) or {}
				res.send_json(JsonResponse{
					error: false
					message: 'Successfully logged in.'
				}, 200)
			}
			'register' {
				data['password'] = bcrypt.generate_from_password(data['password'].bytes(),
					calc_ideal_bcrypt_cost()) or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to hash password.'
					}, 200)
					return
				}

				register_user(mut app.dbconn, data) or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to insert new user into database: $err.msg()'
					}, 200)
					return
				}

				ses.set_many('logged_in', 'true', 'email', data['email']) or {}
				res.send_json(JsonResponse{
					message: 'Successfully registered user.'
				}, 200)
			}
			else {
				res.send_json(JsonResponse{
					error: true
					message: 'Unknown action "' + data['action'] + '" requested.'
				}, 200)
			}
		}
	}
	
	route_logout := fn (req &ctx.Req, mut res ctx.Resp) {
		mut ses := session.start(req, mut res, secure: true)
		ses.delete()
		res.redirect('/dashboard')
	}
	
	route_students := fn [mut app] (req &ctx.Req, mut res ctx.Resp) {
		nameid := req.params['name'].split('-')
		if nameid.len < 2 {
			res.send('404 Not Found - malformatted path', 404)
			return
		}
		id := nameid[nameid.len-1]
		
		student := (app.get_students([id.int()]) or {
			res.send('404 Not Found - No Student', 404)
			return
		})[0]
		
		mut student_html := os.read_file('./html/student.html') or {
			res.send('Internal Server Error', 500)
			return
		}
		
		student_html = student_html.replace('\$vex_insert_student_name', student.name)
		student_html = student_html.replace('\$vex_insert_navbar', app.html_components['navbar'])
		
		res.send_html(student_html, 200)
	}

	mut router := router.new()
	router.route(.get, '/assets/*path', route_assets)
	router.route(.get, '/calendar', route_calendar)
	router.route(.get, '/dashboard', route_dashboard)
	router.route(.get, '/login', route_login)
	router.route(.post, '/login', route_login_post)
	router.route(.get, '/logout', route_logout)
	router.route(.get, '/students/*name', route_students)

	server.serve(router, app.config.value('port').default_to('8080').int())
}

// register_user validates the fields provided in `data`. If
// everything checks out, then user information is inserted
// into database.
fn register_user(mut conn mysql.Connection, data map[string]string) ? {
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

	account_birth := time.sys_mono_now()
	query_insert :=
		"INSERT INTO teachers (username, full_name, email, password, account_birth) VALUES ('" +
		data['username'] + "', '" + data['name'] + "', '" + data['email'] + "', '" +
		data['password'] + "', " + account_birth.str() + ');'
	result_insert := conn.query(query_insert) ?
	if conn.affected_rows() == 0 {
		return error('Failed to insert user into database. ' + result_insert.str())
	}
}

// God's Word does not return void
fn gods_word() bool {
	return true
}
