#!/bin/bash
# ClusterControl API Client using bash
# curl, openssl, python2.6+ must be installed
# usage: clustercontrol_api.sh [-r|-j] [-o]
 
config_file="./clustercontrol.conf"
if [ -f $config_file ]; then
  source $config_file
else
  echo 'Error: Unable to find clustercontrol.conf'
  exit 1
fi
 
check_binary ()
{
  binaries=$*
  for binary in $binaries
  do
    bin_path=`command -v $binary`
    [ -z "$bin_path" ] && echo "Error: Unable to find binary path for $binary" && exit 1
  done
}
 
check_var ()
{
  vars=$*
  for var in $vars
  do
    [ -z "$var" ] && echo "Error: $var is empty" && exit 1
  done
 
}
 
check_binary curl openssl python
check_var ccapi_url ccapi_token
 
## calculate token with sha1
cmon_token=`echo -n "$ccapi_token" | openssl dgst -sha1 | awk {'print $2'}`
unix_timestamp=$(date -d "today" "+%s")
#echo "$unix_timestamp"
 
usage() {
  echo "-i : cluster ID [default=1]"
  echo "-r : retrieve data in JSON format"
  echo "-j : post job to ClusterControl"
  echo "-o : extra parameters when retrieve data"
}
while getopts ":i:r:j:o:" arg; do
  case "$arg" in
    i) cluster_id="$OPTARG" ;;
    r) retrieve="$OPTARG" ;;
    j) job="$OPTARG" ;;
    o) options="$OPTARG" ;;
    -) break ;;
    ?) usage
    exit 1;;
  esac
done
 
[ -z "$cluster_id" ] && cluster_id=1
([ -z "$retrieve" ] && [ -z "$job" ]) && echo "Please specify either -r to retrieve data or -j to post job" && exit 1
([ ! -z "$retrieve" ] && [ ! -z "$job" ]) && echo "Error: -r and -j cannot be used simultaneously" && exit 1
if [ ! -z "$retrieve" ]; then
  group="backups/all backups/glacier_job_status backups/schedules backups/reports backups/storage_location \
  clusters/all clusters/aws_metadata clusters/dbload clusters/info clusters/mongodb_info clusters/host_dbload clusters/master clusters/settings clusters/dbconnections \
  hosts/hosts_stats hosts/all_mysql_host hosts/galera_stat_all hosts/ram_history hosts/network_history hosts/cpu_history hosts/disk_history hosts/cpu_info \
  alarms/all alarms/unread alarms/check_cmon_db \
  counters/all counters/mongo_all \
  nodes/all nodes/repl_info nodes/datanodestats nodes/clusternodes nodes/hostnames nodes/innodb_status \
  performance/performance_meta performance/performance_data performance/probe_info performance/probe_graph_data \
  queries/all queries/top queries/mysql_histogram \
  health/criticalmodules health/memoryusage health/status health/modules \
  jobs/all jobs/unread jobs/message \
  processes/all processes/top processes/mongo_processes \
  email/all \
  "
  i=0
  for f in $group
  do
    [ "$f" == "$retrieve" ] && i=0 && break
    ((i++))
  done
  [ $i -ne 0 ] && echo "Error: Unknown options \"$retrieve\"" && exit 1 
  url="$ccapi_url/$retrieve.json?clusterid=$cluster_id&_dc=$unix_timestamp&$options"
fi
 
post_data=
if [ ! -z "${job}" ]; then
  post_data="-d clusterid=$cluster_id&jobcommand=${job}"
  url="$ccapi_url/jobs/job_command"
fi
 
result=`curl -k -g -s -H "CMON-TOKEN: $cmon_token" "$post_data" "$url"`
echo $result | python -mjson.tool
