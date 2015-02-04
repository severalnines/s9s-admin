#!/bin/sh

XPATH=/var/lib/zabbix/clustercontrol/scripts
cd $XPATH
php -q clustercontrol_stats.php $*
