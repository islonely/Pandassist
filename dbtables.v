module main

import htmlbuilder
import time

// Gender represents all available genders for the human race.
enum Gender {
	male = 0
	female = 1
}

// Student represents a row from the `students` table in the database.
struct Student {
mut:
	id     u64
	name   string
	gender Gender = .female
	avatar_path string
}

// Event represents a row from the `events` table in the database.
struct Event {
mut:
	id u64
	description string
	category string
	time time.Time
}

// html returns the html code for an array of Event
fn (events []Event) html() string {
	mut str := ''
	for event in events {
		str += event.html()
	}
	return str
}

// html returns the html code for an individual Event
fn (event Event) html() string {
	evt_name := event.description.replace(' ', '-') + '-$event.id'
	mut bldr := htmlbuilder.new_builder()
	bldr.open_tag('a', {
		'href': '/events/$evt_name'
		'class': 'student block'
	})
	bldr.open_tag('h4', {
		'class': 'pt-2 leading-tight mb-2'
		'style': 'font-weight: bold;'
	})
	bldr.write_string(event.description)
	bldr.open_tag('span', {
		'class': 'float-right text-manjari text-sm relative'
		'style': 'top: 5px; font-weight: normal;'
	})
	bldr.write_string(fmt_time(event.time))
	bldr.close_all_tags()
	return bldr.str()
}

// <a href="/events/field-trip" class="student block">
    // <h4 class="pt-2 leading-tight mb-2" style="font-weight: bold">
        // Field Trip
        // <span class="float-right text-manjari text-sm relative" style="top: 5px; font-weight: normal;">4-24-2022</span>
    // </h4>
// </a>

// Teacher represents a row from the `teachers` table in the databse.
struct Teacher {
mut:
	id       u64
	username string
	name     string
	email    string
	phone    string
	dob      time.Time
	students []Student
	events   []Event
}

// html returns the html code for an array of Student
fn (students []Student) html() string {
	mut str := ''
	for s in students {
		str += s.html() + '\n'
	}
	return str
}

// html returns the html code for an individual Student
fn (student Student) html() string {
	path := student.name.replace(' ', '-') + '-$student.id'
	gender := student.gender.str()
	mut bldr := htmlbuilder.new_builder()
	bldr.open_tag('a', {
		'href':  '/students/$path'
		'class': 'student flex items-center'
	})
	bldr.open_tag('img', {
		'src':   if student.avatar_path == '' {
			'/assets/img/students/profile-default-${gender}.png'
		} else {
			student.avatar_path
		}
		'class': 'rounded-full h-12 pr-1'
		'style': 'width: 3.25rem !important;'
	})
	bldr.open_tag('h4', {
		'class': 'pt-2 leading-tight mb-2'
		'style': 'font-weight: bold'
	})
	bldr.write_string(student.name)
	bldr.close_all_tags()
	return bldr.str()
}

fn fmt_time(t time.Time) string {
	mut str := t.smonth() + ' ' + t.day.str()
	str += match t.day {
		1, 21, 31 { 'st' }
		2, 22{ 'nd' }
		else { 'th' }
	}
	str += ', ' + t.year.str()
	return str
}