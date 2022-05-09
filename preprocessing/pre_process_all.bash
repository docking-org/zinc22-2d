#!/bin/bash
BINDIR=$(dirname $0)
BINDIR=${BINDIR-.}
tranches=$1
catalog=$2

for pid in $(awk '{print $2}' $BINDIR/database_partitions.txt); do

	bash $BINDIR/pre_process_partition.bash $pid $tranches $catalog
	njobs=$(squeue --array | grep 2dpre | wc -l)
	first=
	while [ $njobs -gt 9000 ]; do
		[ -z $first ] && echo "waiting for space to free up in queue"
		sleep 10
		njobs=$(squeue --array | grep 2dpre | wc -l)
		first=f
	done
	! [ -z $first ] && echo "found space, submitting more!"

done
