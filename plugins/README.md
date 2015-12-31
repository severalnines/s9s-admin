#Plugins#

This directory contains plugins related to ClusterControl:
* nagios - This Nagios plugin pulls database cluster status and alarms (as performance data) from ClusterControl server.
* zabbix - Zabbix template to report database cluster status, backups and alarms on ClusterControl host (Zabbix agent) to Zabbix server.
* pagerduty - This plugin forwards the alarm raise/close events to the PagerDuty system.
* syslog - This plugin writes the new alarms instantly to the syslog.



