#!/usr/bin/env bash

[[ $# -ne 6 ]] && echo "$(basename $0) <dumpfile> <# of splits/chunks. max 20> <# of mysql clients> <db user> <db password> <db schema>" && exit 1
user=$4
password=$5
schema=$6

declare -a hosts=('127.0.0.1' '127.0.0.1')
MYSQL_CMD=mysql

dumpfile=$1
splits=$2
clients=$3

declare -a splitfiles=('xaa'  'xab'  'xac'  'xad'  'xae'  'xaf'  'xag'  'xah'  'xai'  'xaj'  'xak'  'xal' 'xam'  'xan'  'xao'  'xap'  'xaq'  'xar'  'xas'  'xat')

# split file
if [[ -e $dumpfile ]]; then
    mkdir -p staging && cd staging
    echo "splitting $dumpfile into $splits chunks"
    split --verbose --number l/$splits ../$dumpfile
else 
    echo "cannot open $dumpfile"
    exit 1
fi

[[ $clients -gt $splits  ]] && clients=$splits
i=1
for ((i=0;i<splits;i++)); do
    j=$((i%${#hosts[@]}))
    echo "cat ${splitfiles[$i]} | $MYSQL_CMD -f -u${user} -h${hosts[$j]} ${schema}" 
    cat ${splitfiles[$i]} | $MYSQL_CMD -f -u${user} -h${hosts[$j]} ${schema} &
    while [ $(jobs -r | wc -l) -ge $clients  ]; do sleep 1; done
done
echo "done..."
