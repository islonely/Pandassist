module main

import crypto.bcrypt
import time
import vweb
import x.json2

// first 4 digits of error number refer to the category of error.
const(
	const_errno_password_hash_fail = 00010001
	const_err_msg = {
		001001: 'Failed to cryptographically hash the provided password. Please contact support if you see this message.'
	}
)

type Any = json2.Null | []Any | bool | f64 | map[string]Any | string

// JsonResult will be encoded as {"error":false,"message":"error message","code":0,"data":{}}
struct JsonResult {
	error bool
	message string
	code int
	data map[string]Any
}

struct App {
	vweb.Context
}

// login serves the HTML page where the end user is prompted to
// either login or sign up for an account.
['/login']
fn (mut app App) login() vweb.Result {
	return $vweb.html()
}

// calc_ideal_bcrypt_cost automatically determines what the optimal cost for the
// bcrypt algorithm should be. This scales with hardware. So as processors get more
// efficient, the higher the return integer will be.
fn calc_ideal_bcrypt_cost() int {
	mut cost := 8
	mut sw := time.new_stopwatch()
	sw.start()
	hash := bcrypt.generate_from_password('microbenchmark'.bytes(), cost) or {''}
	sw.stop()
	mut duration_ms := sw.elapsed().milliseconds()
	
	if hash == '' { return 0 }
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

// handle_login decides what should happen upon a post request to
// the login page.
['/login'; post]
fn (mut app App) handle_login() vweb.Result {
	match app.form['action'] {
		'login' {
		// future proof bcrypt passwords by updating the hashed password
		// if the user submits correct password.
		}
		'register' {
			hashed := bcrypt.generate_from_password(app.form['password'].bytes(), calc_ideal_bcrypt_cost()) or {''}
			if hashed == '' {
				return app.json(JsonResult{
					error: true,
					message: const_err_msg[const_errno_password_hash_fail],
					code: const_errno_password_hash_fail
				})
			}
			register_user(app.form) or {
				return app.json(JsonResult{
					error: true,
					message: err.msg
					code: err.code
				})
			}
			return app.json(JsonResult{
				message: 'Successfully created user!'
			})
		}
		else {}
	}
	return app.redirect('/login')
}

// register_user validates the fields provided by a POST request form.
// It then submits the provided information into a database.
// NOTE: I have not finished this function yet.
fn register_user(form map[string]string) ? {
	mut conn := new_connection()
	conn.connect()?
	defer {
		conn.close()
	}
	query_username_taken := 'SELECT * FROM teachers WHERE username=\'' + form['username'] + '\';'
	query_email_taken := 'SELECT * FROM teachers WHERE email=\'' + form['email'] + '\';'
	result_username_taken := conn.query(query_username_taken)?
	if result_username_taken.n_rows() > 0 {
		return const_mysql_error_username_taken
	}
	result_email_taken := conn.query(query_email_taken)?
	if result_email_taken.n_rows() > 0 {
		return const_mysql_error_email_taken
	}
}

fn main() {
	mut app := App{}
	
	app.mount_static_folder_at('./assets', '/assets')
	
	vweb.run(app, 8080)
}
