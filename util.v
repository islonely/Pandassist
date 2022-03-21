module main

import crypto.bcrypt
import time

// calc_ideal_bcrypt_cost automatically determines what the optimal cost for the
// bcrypt algorithm should be. This scales with hardware. So as processors get more
// efficient, the higher the return integer will be. Returns `bcrypt.default_cost` on error.
fn calc_ideal_bcrypt_cost() int {
	mut cost := 1
	mut sw := time.new_stopwatch()
	sw.start()
	hash := bcrypt.generate_from_password('microbenchmark'.bytes(), cost) or {''}
	sw.stop()
	if hash == '' { return bcrypt.default_cost }
	
	mut duration_ms := sw.elapsed().milliseconds()
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