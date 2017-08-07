redis-expiring_counter
======================

The redis-expiring_counter gem builds a counter on top of redis allowing for fast and  
accurate rate limiting.  Currently, it should work fine for limiting actions up to a  
couple thousand per second.

Please let me know if you find a way to make this better.

Cheers,  
[Sean Vikoren](http://vikoren.com)  

<br />

Example Usage:

	require "redis-expiring_counter"

	google_duration_of_limit_in_seconds = 24 * 60 * 60
	google_max_calls_per_day = 2500

	google_counter = RedisExpiringCounter.new("google", google_duration_of_limit_in_seconds, google_max_calls_per_day)

	20.times do
	  if google_counter.increment
	    # call google api
	  end
	end

<br />
<br />
<br />
<br />
<br />
<br />
<br />
<br />

