module main

import crypto.bcrypt
import htmlbuilder
import json
import nedpals.vex.ctx
import nedpals.vex.router
import nedpals.vex.server
import nedpals.vex.session
import os
import rand
import crypto.sha1
import toml


const (
	max_avatar_size = 1048576 // 1 MB in bytes
	students_avatar_dir = './assets/img/students/'
)

// App is an extension of Router from the nedpals.vex module.
struct App {
mut:
	config toml.Doc
	html_components map[string]string
}

// JsonResponse is the the response sent back upon post request.
// Mainly to send back to a jQuery $.ajax request.
struct JsonResponse {
	message string
	error   bool
	data    map[string]string
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

	// serves files in the assets directory on the specified path
	route_assets := fn (req &ctx.Req, mut res ctx.Resp) {
		res.send_file('./assets/' + req.params['path'], 200)
	}

	route_calendar := fn [app] (req &ctx.Req, mut res ctx.Resp) {
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

		// just checking to see if teacher exists in database
		_ := app.get_teacher(ses) or {
			res.send('Internal Server Error', 500)
			println(err.msg())
			return
		}

		res.send_html(calendar_html, 200)
	}

	route_dashboard := fn [app] (req &ctx.Req, mut res ctx.Resp) {
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

		teacher := app.get_teacher(ses) or {
			res.send('Internal Server Error', 500)
			println(err.msg())
			return
		}
		
		dashboard_html = dashboard_html.replace('\$vex_insert_students', teacher.students.html())
		dashboard_html = dashboard_html.replace('\$vex_insert_events', teacher.events.html())

		res.send_html(dashboard_html, 200)
	}
	
	route_events:= fn [app] (req &ctx.Req, mut res ctx.Resp) {
		nameid := req.params['name'].split('-')
		if nameid.len < 2 {
			res.send('404 Not Found - malformatted path', 404)
			return
		}
		id := nameid[nameid.len-1]
		
		event := (app.get_events([id.int()]) or {
			res.send('404 Not Found - no event', 404)
			return
		})[0]
		
		mut event_html := os.read_file('./html/event.html') or {
			res.send('Internal Server Error', 500)
			return
		}
		
		event_html = event_html.replace('\$vex_insert_event_name', event.description)
		event_html = event_html.replace('\$vex_insert_navbar', app.html_components['navbar'])
		
		res.send_html(event_html, 200)
	}

	// route_login serves the login page to the end user
	route_login := fn (req &ctx.Req, mut res ctx.Resp) {
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
	route_login_post := fn [app] (req &ctx.Req, mut res ctx.Resp) {
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
				mut conn := new_connection(app.config)
				conn.connect() or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to connect to database. $err.msg()'
					}, 200)
					return
				}
				defer {
					conn.close()
				}

				query_hashword := "SELECT password FROM teachers WHERE email='" + data['email'] +
					"';"
				result_hashword := conn.query(query_hashword) or {
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
				conn.query(query_update_password) or {
					res.send_json(JsonResponse{
						error: false
						message: 'Notice: Failed to insert new password hash.'
					}, 200)
					return
				}

				if conn.affected_rows() == 0 {
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

				app.register_user(data) or {
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
	
	route_students := fn [app] (req &ctx.Req, mut res ctx.Resp) {
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
	
	route_insert_post := fn [app] (req &ctx.Req, mut res ctx.Resp) {
		mut data := req.parse_form() or {
			res.send_json(JsonResponse{
				error: true
				message: 'Failed to parse form data: $err.msg()'
			}, 200)
			return
		}
		
		mut ses := session.start(req, mut res, secure: true)
		
		match req.params['table'] {
			'students' {
				if ('name' in data) && ('gender' in data) {
				    if data['name'].len == 0 ||
				       data['gender'].len == 0 {
				        res.send_json(JsonResponse{
				            error: true
				            message: 'Error: Inserting new student expects that length of name and gender be greater than zero.'
				        }, 200)
				        return
				    }
					mut student := Student{
						name: data['name']
						gender: Gender(data['gender'].int())
					}
					student.avatar_path = if 'avatar_path' in data { data['avatar_path'] } else { if student.gender == .male { '/assets/img/students/profile-default-male.png' } else { '/assets/img/students/profile-default-female.png' } }
					mut conn := new_connection(app.config)
					conn.connect() or {
						res.send('Internal Server Error', 500)
						return
					}
					defer {
						conn.close()
					}
					
					query := 'INSERT INTO `students` (name, gender, avatar_path) VALUES (\'$student.name\', ${int(student.gender)}, \'$student.avatar_path\');'
					conn.query(query) or {
						res.send('Internal Server Error', 500)
						println(err.msg())
						return
					}
					
					if conn.affected_rows() == 0 {
						res.send_json(JsonResponse{
							error: true
							message: 'Unexpectedly failed to insert student.'
						}, 200)
						return
					}
					
					student.id = u64(conn.last_id() as int)
					
					teacher := app.get_teacher(ses) or {
						res.send('Internal Server Error', 500)
						println(err.msg())
						return
					}
					
					query_teacher := 'UPDATE `teachers` SET students=CONCAT(students, \',$student.id\') WHERE id=$teacher.id;'
					conn.query(query_teacher) or {
						res.send('Internal Server Error', 500)
						println(err.msg())
						return
					}
					
					if conn.affected_rows() == 0 {
						res.send_json(JsonResponse{
							error: true
							message: 'Unexpectedly failed to update teacher.'
						}, 200)
						return
					}
					
					res.send_json(JsonResponse{
						message: 'Successfully created student.'
					}, 200)
				} else {
					res.send_json(JsonResponse{
						error: true
						message: 'Malformat: Inserting new student expects a name and gender post field.'
					}, 200)
					return
				}
			}
			else {
				res.send('404 Not Found', 404)
			}
		}
	}
	
	route_upload_post := fn (req &ctx.Req, mut res &ctx.Resp) {
		data := req.parse_files() or {
			res.send_json(JsonResponse{
				error: true
				message: 'Failed to parse form data: ${err.msg()}'
			}, 200)
			return
		}
		
		match req.params['type'] {
			'student-avatar' {
				if !('file' in data) {
					res.send_json(JsonResponse{
						error: true
						message: 'No file provided to upload.'
					}, 200)
					return
				}
								
				file := data['file'][0]
				if file.content.len == 0 || file.content.len > max_avatar_size {
					res.send_json(JsonResponse{
						error: true
						message: 'Provided file is either empty or larger than $max_avatar_size bytes.'
					}, 200)
					return
				}
				
				mut filename := sha1.hexhash(rand.uuid_v4()) + os.file_ext(file.filename)
				// it seems somewhere somehow seemingly sporadic files will have the name
				// and/or file type corrupted, but the data itself is still intact.
				if file.filename.runes().len > 0 || file.content_type.runes().len > 0 {
					// the extension itself is irrelevant since you read the file header
					// bytes to determine file type
					filename += '.png'
				}
				
				os.write_file_array(students_avatar_dir + filename, file.content) or {
					res.send_json(JsonResponse{
						error: true
						message: 'Failed to write file: ${err.msg()}'
					}, 200)
					return
				}
				
				res.send_json(JsonResponse{
					message: 'Successfully uploaded file.'
					data: {
						'path': filename
						'size': file.content.len.str()
					}
				}, 200)
			}
			else {
				res.send('404 Not Found', 404)
				return
			}
		}
	}

	mut router := router.new()
	// alphabetized
	router.route(.get, '/assets/*path', route_assets)
	router.route(.get, '/calendar', route_calendar)
	router.route(.get, '/dashboard', route_dashboard)
	router.route(.get, '/events/*name', route_events)
	router.route(.post, '/insert/*table', route_insert_post)
	router.route(.get, '/login', route_login)
	router.route(.post, '/login', route_login_post)
	router.route(.get, '/logout', route_logout)
	router.route(.get, '/students/*name', route_students)
	router.route(.post, '/upload/*type', route_upload_post)

	server.serve(router, app.config.value('port').default_to('8080').int())
}

// God's Word does not return void
[inline]
fn gods_word() bool {
	return true
}
