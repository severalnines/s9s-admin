#!/usr/bin/env bash

[ $# -lt 2 ] && echo "$(basename $0) <source dir> <localhost|remote host> [port|8888] [compression level|5]" && exit 1

[ ! $(command -v nc) ] && echo "Unable to find nc. Please install it first." && exit 1
[ ! $(command -v gzip) ] && echo "Unable to find gzip. Please install it first." && exit 1
[ ! $(command -v pigz) ] && echo "Unable to find pigz. Please install it first." && exit 1
[ ! $(command -v pv) ]  && echo "Unable to find pv. Please install it first." && exit 1

[[ ! -d "$1" && ! -L $1 ]] && echo "$1 is not a directory!" && exit

remote_host=localhost
port=8888
c=5
[ $# -gt 1 ] && remote_host=$2
[ $# -gt 2 ] && remote_host=$2&&port=$3
[ $# -gt 3 ] && remote_host=$2&&port=$3&&c=$4
dir=$1

size=$(du -sh $dir | cut -f1)
if [ $remote_host = "localhost" ]
then
	echo "Sending content of $dir ($size) on $remote_host:$port with compression level $c..."
	[[ $OSTYPE =~ ^darwin ]] && tar -c $1 | pv -tab | tee >(shasum > /dev/stderr) | pigz -$c | nc -l $port
	[[ ! $OSTYPE =~ ^darwin ]] && tar -c $1 | pv -tabes $(du -sb $dir | cut -f1) | tee >(sha1sum > /dev/stderr) | pigz -$c | nc -l $port
else
	echo "Sending content of $dir ($size) to $remote_host:$port with compression level $c..."
	[[ $OSTYPE =~ ^darwin ]] && tar -c $1 | pv -tab | tee >(shasum> /dev/stderr) | pigz -$c | nc $remote_host $port
	[[ ! $OSTYPE =~ ^darwin ]] && tar -c $1 | pv -tabes $(du -sb $dir | cut -f1) | tee >(sha1sum > /dev/stderr) | pigz -$c | nc $remote_host $port
fi
echo "Done!"
