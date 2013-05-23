s9s-admin
=========

s9s-admin tools, like s9s_backup, s9s_haproxy, s9s_change_passwd has a home here.

s9s-admin/cluster

* s9s_backup - create and restore backups using xtrabackup (for Galera and Replication clusters)

* s9s_backup_wd - watchdog for s9s_backup

* s9s_clone - clone Galera or Replication clusters, by forking off a node to a new Cluster

* s9s_haproxy - to manage haproxy (for Galera, Replication, and MySQL Cluster)

* s9s_rebuild_slave - used by cmon to rebuild failed slaves (Replication cluster)

* s9s_galera - manage galera from command line

* s9s_aws - change ip / hostname in cmon if EC2 instance changed ip

You can copy the s9s-admin/cluster  to /usr/bin/ or run them from s9s-admin/cluster.

s9s_backup* must be installed on all nodes in /usr/bin/ 


s9s-admin/ccadmin

* s9s_change_password - change password for the cmon and the root user on all nodes in the cluster

* s9s_sw_update - update SW packages before performing an upgrade


s9s-admin/plugins

Plugins to external tools, e.g to nagios


For more information, go into the directories above and read the README files.
