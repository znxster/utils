#!/bin/bash

# max concurrency
MAX_JOBS=3

# quit when asked to
trap 'exit' SIGTERM SIGINT

function parallel {
	# process parameters
	local commands=""
	if [ -z "$1" ]; then
		echo "usage: parallel 'command' 'description'"
		exit 1
	else
		commands="$1"
	fi

	local description=""
	if [ -z "$2" ]; then
		description="$1"
	else
		description="$2"
	fi

	# start/end times
	local time_start=$(date +"%H:%M:%S")
	local time_end=""

	# run commands
	echo "$time_start (start) : $description" && \
	( eval $commands ) && \
	time_end=$(date +"%H:%M:%S") && \
	echo "$time_end (  end) : $description" &

	# check number of active jobs, wait if maxed
	local pids=$(jobs -p -r | wc -l)
	if [ $pids -ge $MAX_JOBS ]; then
		echo "$time_start (maxed) : $MAX_JOBS concurrent"
		wait -n
	fi
}

# example loop call
for sleeptimer in 10 3 7 5 1 8 2; do
	parallel "sleep $sleeptimer" "sleeping ${sleeptimer}s"
done

# example multiple command call
parallel "sleep 4; echo 'waited four'; echo 'which is good'" "action_four"
parallel "echo 'this is another action but runs before action_four'; sleep 1" "antoher_action"

# always have this at end, to ensure that you have waited for the children to
# finish before ending
wait
