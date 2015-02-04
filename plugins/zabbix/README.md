ClusterControl Template for Zabbix
==================================

This template is a collection of scripts to report database cluster status, backups and alarms (warning & critical) on ClusterControl host (Zabbix agent).

- The items are populated by polling Zabbix agent
- There are predefined triggers available to use

System Requirements
===================

- Zabbix version 2.2.x. The actual testing has been done on version 2.2.8 (revision 51174)
- Zabbix agent, php-cli/php5-cli, php-common/php5-common, git, curl, openssl, python2.6+
- ClutserControl is running on the agent host
- Tested database cluster: Galera cluster, MySQL single and replication

Installation Instructions
=========================

Configure Zabbix Agent
----------------------

On Zabbix agent host aka ClusterControl host, run following command:

1) Get the package from github:
```bash
git clone https://github.com/severalnines/s9s-admin
```

2) Create a template directory for ClusterControl under `/var/lib/zabbix` and copy `scripts` directory into it:
```bash
mkdir -p /var/lib/zabbix/clustercontrol
cp -Rf ~/s9s-admin/plugins/zabbix/agent/scripts /var/lib/zabbix/clustercontrol
```

3) Copy the ClusterControl template user paramater file into `/etc/zabbix/zabbix.agent.d/`:
```bash
cp -f ~/s9s-admin/plugins/zabbix/agent/userparameter_clustercontrol.conf /etc/zabbix/zabbix.agent.d/
```

4) This template uses ClusterControl API to collect stats. Configure the value of ClusterControl  API URL and token inside `/var/lib/zabbix/clustercontrol/scripts/clustercontrol.conf`, similar to example below:
```bash
ccapi_url='https://192.168.1.101/cmonapi'
ccapi_token='39b9db69a538f09273b3cb482df4192006662a43'
```
** *If you do not configure this correctly, the script will not work. **

5) Test the script by invoking a cluster ID and `test` argument:
```bash
/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.sh 1 test
GALERA
```

You should get an output of your database cluster type, indicating the script is able to retrieve information using the provided ClusterControl API and token in `clustercontrol.conf`.

Configure Zabbix Server
-----------------------

1. Download the Zabbix template file from [here](https://raw.githubusercontent.com/severalnines/s9s-admin/master/plugins/zabbix/server/zbx_clustercontrol_templates.xml) to your desktop.

2. Import the XML template using Zabbix UI (Configuration > Templates > Import).

3. Create/edit hosts and linking them the template "ClusterControl Template" (Configuration > Hosts > choose a host > Templates tab).

You are done.

Monitoring Data
===============

Item key
--------

The template will report following items' key from ClusterControl:

* `clustercontrol.db.status` 	- Database cluster status.
* `clustercontrol.db.backups` - Backup status. If it finds error on any created backups, it will raise a trigger.
* `clustercontrol.db.alarms-critical` - The number of unignored alarms raised by ClusterControl with critical severity.
* `clustercontrol.db.alarms-warning` - The number of unignored alarms raised by ClusterControl with warning severity.

User Parameter
--------------

The default user parameter configuration file assumes you are running one database cluster under ClusterControl with cluster ID 1. If you want to monitor more clusters, just append the same parameters with respective cluster ID value.

E.g: For cluster ID 3, the user parameter should be:
```bash
UserParameter=clustercontrol.db.status,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.php 3 cluster
UserParameter=clustercontrol.db.backups,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.php 3 backups
UserParameter=clustercontrol.db.alarms-warning,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.php 3 alarms-warning
UserParameter=clustercontrol.db.alarms-critical,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.php 3 alarms-critical
```

Debugging
=========

- Set DebugLevel=4 on /etc/zabbix/zabbix_agentd.conf
- Use zabbix_get to retrieve monitoring data from Zabbix server
- Zabbix log file: /var/log/zabbix/zabbix_agentd.log
