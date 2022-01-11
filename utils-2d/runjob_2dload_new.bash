#!/bin/bash
# utils-2d/runjob_2dload_new.bash
joblist=$1
bindir=$2

id=$SLURM_ARRAY_TASK_ID

port_args=$(head -n $id $joblist | tail -n 1)

port=$(echo $port_args | awk '{print $1}')
args=$(echo $port_args | awk '{$1=""; print $0}')

echo $port $args

source $bindir/../py36_psycopg2/bin/activate

eval python $bindir/../2dload.py $port $args