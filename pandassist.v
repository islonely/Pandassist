module main

import crypto.bcrypt
import mysql
import nedpals.vex.ctx
import nedpals.vex.router
import nedpals.vex.server
import json
import time
import toml

// App is an extension of Router from the nedpals.vex module.
struct App {
mut:
	config toml.Doc
	dbconn mysql.Connection
}

// fn (mut app App) route(method router.Method, path string, func fn(&ctx.Req, mut ctx.Resp)) {
// 	app.router.route(method, path, func)
// }

// JsonResponse is the the response sent back upon post request.
// Mainly to send back to a jQuery $.ajax request.
struct JsonResponse {
	message string
	error bool
}

// str returns JsonResponse as a JSON encoded string.
fn (jr JsonResponse) str() string {
	return json.encode(jr)
}

fn main() {
	mut app := App{
		config: parse_toml(const_config_path)   // see io.v
	}
	app.dbconn = new_connection(app.config) // see db.v
	
	// serves files in the assets directory on the specified path
	route_assets :=  fn (req &ctx.Req, mut res ctx.Resp) {
		res.send_file('./assets/' + req.params['path'], 200)
	}
	
	// route_login serves the login page to the end user
	route_login := fn (req &ctx.Req, mut res ctx.Resp) {
		res.send_file('./html/login.html', 200)
	}
	
	// route_login_post handles post request made to the login
	// route. This will either be a request to login or to
	// register a new user.
	route_login_post := fn [mut app] (req &ctx.Req, mut res ctx.Resp) {
		mut data := req.parse_form() or {
			res.send_json(JsonResponse{
				error: true
				message: 'Failed to parse form data: $err.msg'
			}, 200)
			return
		}
		
		match data['action'] {
			'login' {
				// Future proof bcrypt password by updating the hashed
				// password if the user submits correct password.
			}
			'register' {
				data['password'] = bcrypt.generate_from_password(data['password'].bytes(), calc_ideal_bcrypt_cost()) or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to hash password.'
					}, 200)
					return
				}
				
				register_user(mut app.dbconn, data) or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to insert new user into database: $err.msg'
					}, 200)
					return
				}
				
				res.send_json(JsonResponse{
					message: 'Successfully registered user.'
				}, 200)
				return
			}
			else {
				res.send_json(JsonResponse{
					error: true
					message: 'Unknown action "' + data['action'] + '" requested.'
				}, 200)
			}
		}
	}
	
	mut router := router.new()
	router.route(.get, '/assets/*path', route_assets)
	router.route(.get, '/login', route_login)
	router.route(.post, '/login', route_login_post)
	
	server.serve(router, app.config.value('port').default_to('8080').int())
}

// register_user validates the fields provided in `data`. If
// everything checks out, then user information is inserted
// into database.
fn register_user(mut conn mysql.Connection, data map[string]string) ? {
	conn.connect()?
	defer { conn.close() }
	
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
	query_username_taken := 'SELECT * FROM teachers WHERE username=\'' + data['username'] + '\';'
	result_username_taken := conn.query(query_username_taken)?
	if result_username_taken.n_rows() > 0 {
		return const_mysql_error_username_taken
	}
	
	// Check if email is taken.
	query_email_taken := 'SELECT * FROM teachers WHERE email=\'' + data['email'] + '\';'
	result_email_taken := conn.query(query_email_taken)?
	if result_email_taken.n_rows() > 0 {
		return const_mysql_error_email_taken
	}
	
	account_birth := time.sys_mono_now()
	query_insert := 'INSERT INTO teachers (username, full_name, email, password, account_birth) VALUES (\'' + data['username'] + '\', \'' + data['name'] + '\', \'' + data['email'] + '\', \'' + data['password'] + '\', ' + account_birth.str() + ');'
	result_insert := conn.query(query_insert)?
	if conn.affected_rows() == 0 {
		return error('Failed to insert user into database. ' + result_insert.str())
	}
}