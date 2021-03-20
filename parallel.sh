#!/bin/bash

lock_file=$(mktemp)
worker_count=$1
shift 1
task=$*

on_exit() { rm -f $lock_file; }
trap on_exit EXIT

read_next() {
    (
	flock -x 200
	read line
	echo $line
    ) 200> $lock_file
}

spawn_worker() {
    next_item=$(read_next)
    while [ -n "$next_item" ]; do
	$task "$next_item"
	next_item=$(read_next)
    done
}

for i in $(seq $worker_count) do; spawn_worker &; done <&0
wait $(jobs -pr)
