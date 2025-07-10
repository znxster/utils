#!/bin/bash

# Generates a random password.

# might break due to charset, so force default to C
LANG=C

function random_pass {
	local length=20
	if [ ! -z "$1" ]; then
		length=$1
	fi
	
	# the following will:
	# - remove all non-alphanumeric characters from urandom
	# - wrap the at the desired length
	# - grab top 10 lines
	# - ensure at least one uppercase is present
	# - ensure at least one lowercase is present
	# - ensure at least one digit is present 
	# - provide top line
	
	tr -cd '[:alnum:]' < /dev/urandom | \
		fold -w $length | \
		head -n 10 | \
		grep '[[:upper:]]' | \
		grep '[[:digit:]]' | \
		grep '[[:lower:]]' | \
		head -n 1
}

# examples
random_pass
random_pass 10
random_pass 50

# or allow script to set value
random_pass $1
