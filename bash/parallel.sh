#!/bin/bash

MAX_JOBS=3

function parallel {
	if [ -z "$1" ]; then
		echo "usage: parallel 'command' 'description'"
		exit 1
	fi

	CMD=$1
	DESC=$1
	if [ ! -z "$2" ]; then
		DESC="$2"
	fi

	local time_start=$(date +"%H:%M:%S")
	local time_end=""

	echo "$time_start (start) : $DESC"

	( $CMD ) && \
	time_end=$(date +"%H:%M:%S") && \
	echo "$time_end (  end) : $DESC" &

	local pids=$(jobs -p -r | wc -l)
	if [ $pids -ge $MAX_JOBS ]; then
		echo "$time_start (maxed) : $MAX_JOBS concurrent"
		wait -n
	fi
}

for sleeptimer in 10 3 7 5 1 8 2; do
	parallel "sleep $sleeptimer" "sleeping ${sleeptimer}s"
done

wait
