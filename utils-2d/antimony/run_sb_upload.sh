#! /bin/bash

cd $BINDIR/2dload
HOST=$(hostname | cut -d'.' -f1)
task_id=$SLURM_ARRAY_TASK_ID

port=$(grep $HOST $BINDIR/common_files/current_antimony_databases.txt | head -n $task_id | tail -n 1 | awk '{print $2}')
part=$(grep $HOST $BINDIR/common_files/current_antimony_databases.txt | head -n $task_id | tail -n 1 | awk '{print $3}')

transid=$(ls /nfs/exh/zinc22/antimony/src/$part/*.txt | sort | sha1sum | head -c 10)
source py36_psycopg2/bin/activate
python 2dload.py $port antimony upload $transid /nfs/exh/zinc22/antimony/diff/$part
