#!/usr/bin/env bash

[ $# -lt 3 ] && echo "$(basename $0) <local port> <remote host> <port>" && exit 1

[ ! $(command -v nc) ] && echo "Unable to find nc. Please install it first." && exit 1
[ ! $(command -v gzip) ] && echo "Unable to find gzip. Please install it first." && exit 1
[ ! $(command -v pigz) ] && echo "Unable to find pigz. Please install it first." && exit 1
[ ! $(command -v pv) ]  && echo "Unable to find pv. Please install it first." && exit 1

local_port=$1
remote_host=$2
remote_port=$3

pipe=/tmp/fifo
rm -f $pipe
mkfifo $pipe

echo "Receiving from localhost:$port to pipe $pipe..."
nc $remote_host $remote_port <$pipe &
pid=$!
[[ $OSTYPE =~ ^darwin ]] && nc -l $local_port | tee $pipe | pigz -d | pv -tab | tee >(shasum > /dev/stderr) |tar xf -
[[ ! $OSTYPE =~ ^darwin ]] && nc -l $local_port | tee $pipe | pigz -d | pv -tab | tee >(sha1sum > /dev/stderr) |tar xf -
kill -9 $pid &>/dev/null
rm -f $pipe
echo "Done!"