#!/usr/bin/env bash

[ $# -lt 1 ] && echo "$(basename $0) <localhost|remote host> [port|8888]" && exit 1

[ ! $(command -v nc) ] && echo "Unable to find nc. Please install it first." && exit 1
[ ! $(command -v gzip) ] && echo "Unable to find gzip. Please install it first." && exit 1
[ ! $(command -v pigz) ] && echo "Unable to find pigz. Please install it first." && exit 1
[ ! $(command -v pv) ]  && echo "Unable to find pv. Please install it first." && exit 1

host=localhost
port=8888
[ $# -gt 1 ] && port=$2
host=$1

if [ $host = "localhost" ]
then
echo "Receiving on $port..."
[[ $OSTYPE =~ ^darwin ]] && nc -l $port | pigz -d | pv -tab | tee >(shasum > /dev/stderr) |tar xf -
[[ ! $OSTYPE =~ ^darwin ]] && nc -l $port | pigz -d | pv -tab | tee >(sha1sum > /dev/stderr) |tar xf -
else
echo "Receiving from $host:$port..."
[[ $OSTYPE =~ ^darwin ]] && nc $host $port | pigz -d | pv -tab | tee >(shasum > /dev/stderr) |tar xf -
[[ ! $OSTYPE =~ ^darwin ]] && nc $host $port | pigz -d | pv -tab | tee >(sha1sum > /dev/stderr) |tar xf -
fi
echo "Done!"