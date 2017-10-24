ClusterControl Template for Zabbix 2.0
======================================

Use this template to report database cluster status, and alarms (warning & critical) on ClusterControl host (Zabbix agent) to Zabbix server.

- The items are populated by polling Zabbix agent
- There are predefined triggers available to use

System Requirements
===================

- Zabbix version 3.x. The actual testing has been done on version 3.4.2 (revision 72885)
- Zabbix agent, php-cli/php5-cli, php-common/php5-common, php-curl
- ClusterControl is running on the Zabbix agent host

Installation Instructions
=========================

Configure Zabbix Agent
----------------------

On Zabbix agent host aka ClusterControl host, run following command (omit sudo if you run as root):

1) Get the package from GitHub:
```bash
$ git clone https://github.com/severalnines/s9s-admin
```

2) Create a template directory for ClusterControl under `/var/lib/zabbix` and copy `scripts` directory into it:
```bash
$ sudo mkdir -p /var/lib/zabbix/clustercontrol
$ sudo cp -Rf ~/s9s-admin/plugins/zabbix/agent/scripts /var/lib/zabbix/clustercontrol
```

3) Copy the ClusterControl template user parameter file into `/etc/zabbix/zabbix.agent.d/`:
```bash
$ sudo cp -f ~/s9s-admin/plugins/zabbix/agent/userparameter_clustercontrol.conf /etc/zabbix/zabbix.agent.d/
```

4) This template uses ClusterControl CMON RPC interface to collect stats. The script will copy `/var/www/html/clustercontrol/bootstrap.php` into the template directory to read ClusterControl configuration options. If you are running on non-default path for ClusterControl UI, configure the exact path manually inside `clustercontrol_stats.php`, similar to example below:
```php
$BOOTSTRAP_PATH = '/var/www/html/clustercontrol/bootstrap.php';
```
** If you do not configure this correctly, the script will not work.

5) Test the script by invoking cluster ID and `test` argument (multiple cluster IDs are supported):
```bash
$ sudo /var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.sh 1,2,3,4,5 test
Cluster ID: 1, Cluster Name: MariaDB 10.1, Cluster Type: galera, Cluster Status: STARTED
Cluster ID: 2, Cluster Name: PostgreSQL, Cluster Type: postgresql_single, Cluster Status: STARTED
Cluster ID: 3, Cluster Name: MySQLRep, Cluster Type: replication, Cluster Status: STARTED
Cluster ID 4 not found.
Cluster ID 5 not found.
```

** This example shows that this ClusterControl instance only has 3 clusters, although we specified 5 cluster IDs in the command line.

You should get an output of your database cluster summary, indicating the script is able to retrieve information using the provided ClusterControl RPC interface with correct token in `bootstrap.php`.

6) Finally, restart Zabbix agent:
```bash
$ sudo service zabbix-agent restart
```

Configure Zabbix Server
-----------------------

1) Due to [this bug](https://support.zabbix.com/browse/ZBXNEXT-1679), we need to manually create the value mapping for ClusterControl items in Zabbix server. Log into the Zabbix front-end UI and go to *Administration > General > Value Mapping (the drop-down list) > Create Value Map* as per below:

```
Name: ClusterControl DB Cluster Status
Value:
0 = Failed
1 = Active
2 = Degraded
3 = Unknown
```

** Please follow the exact name/value as above. If you skip this step, the import will fail.

2) Download the Zabbix template file from [here](https://raw.githubusercontent.com/severalnines/s9s-admin/master/plugins/zabbix/server/zbx_clustercontrol_templates.xml) to your desktop.

3) Import the XML template using Zabbix UI (*Configuration > Templates > Import*).

4) Create/edit hosts and linking them the template "ClusterControl Template" (*Configuration > Hosts > choose a host > Templates tab*).

You are done.

Monitoring Data
===============

Item key
--------

The template will report following items' key from ClusterControl:

* `clustercontrol.db.status` - Database cluster status.
* `clustercontrol.db.alarms-critical` - The number of unignored alarms raised by ClusterControl with critical severity.
* `clustercontrol.db.alarms-warning` - The number of unignored alarms raised by ClusterControl with warning severity.
* `net.tcp.service[http,,9500]` - Status of ClusterControl Controller service (cmon).
* `net.tcp.service[http,,9511]` - Status of ClusterControl SSH service (web-based SSH inside ClusterControl UI).
* `net.tcp.service[http,,9510]` - Status of ClusterControl Events service (third-party integration with external notification service like PagerDuty and Slack).

User Parameter
--------------

The default user parameter file assumes you are running a database cluster under ClusterControl with cluster ID 1. If you want to monitor multiple clusters, specify a comma-delimited value of cluster IDs on the second argument.

Example below shows user parameters to monitor multiple clusters with ID 1,2 and 5:
```bash
UserParameter=clustercontrol.db.status,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.sh 1,2,5 cluster
UserParameter=clustercontrol.db.alarms-warning,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.sh 1,2,5 alarms-warning
UserParameter=clustercontrol.db.alarms-critical,/var/lib/zabbix/clustercontrol/scripts/clustercontrol_stats.sh 1,2,5 alarms-critical
```

Debugging
=========

- Set `DebugLevel=4` on `/etc/zabbix/zabbix_agentd.conf`
- Use zabbix_get to retrieve monitoring data from Zabbix server
- Zabbix log file: `/var/log/zabbix/zabbix_agentd.log`
