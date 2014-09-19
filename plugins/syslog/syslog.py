#!/usr/bin/python2
#
# SysLog example plugin for cmon.
#
# Copyright 2014 severalnines.com
# Author: David Kedves <kedazo@severalnines.com>
#
# Dependencies: Python 2.x, python-requests
#
#  2014-06-13 - Initial version
#
import sys
import json
import syslog

jsonInput = ""
for line in sys.stdin:
    jsonInput += line

jsonObj = json.loads (jsonInput)

# exit if type is not alarm
if jsonObj["type"]  != "alarm":
    print "This plugin only supports 'alarm' events, exiting..."
    sys.exit(1)

# do nothing on update
if jsonObj["action"] == "update":
    print "Skipping 'update' alarm event..."
    sys.exit(1)

alarmObj = jsonObj["alarm"]
priority = syslog.LOG_INFO
if alarmObj["severity"] == "ALARM_WARNING":
    priority = syslog.LOG_WARNING
elif alarmObj["severity"] == "ALARM_CRITICAL":
    priority = syslog.LOG_CRIT

syslog.openlog (ident="cmon-syslog-plugin", facility=syslog.LOG_USER)

syslog.syslog (priority, "cluster-" + str(alarmObj["cid"]) + ", " + \
               jsonObj["action"] + " alarm: " + alarmObj["name"] + \
               " (id=" + str(alarmObj["id"]) + ")")

syslog.closelog()