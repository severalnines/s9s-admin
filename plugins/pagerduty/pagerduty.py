#!/usr/bin/python2
#
# PagerDuty example plugin for cmon.
#
# Copyright 2014 severalnines.com
# Author: David Kedves <kedazo@severalnines.com>
#
# Dependencies: Python 2.x, python-requests
#
# Change-history:
#  2014-09-17 - v3, config. file support
#  2014-06-11 - v2, ticket auto-resolving is implemented
#  2014-05-20 - Initial version (only supports event triggering)
#
import sys
import json
import ConfigParser

try:
    import requests
except ImportError:
    print "PagerDuty plugin"
    print "Exiting, as python-requests not installed (please install it)."
    sys.exit(1)

resteventurl = "https://events.pagerduty.com/generic/2010-04-15/create_event.json"
restapikey   = ""

#
# In order to enable this plugin, you should edit the
# cmon plugins configuration file ( /etc/cmon_plugins.ini ):
# 
# [pagerduty]
# api_key=WRITE_YOUR_API_KEY_HERE
#
config = ConfigParser.RawConfigParser()
config.read("/etc/cmon_plugins.ini")
if config.has_option("pagerduty", "api_key"):
    restapikey = config.get("pagerduty", "api_key")

if restapikey == "":
    print "PagerDuty API key is not set, exiting..."
    sys.exit(0)

print "api_key = " + restapikey

jsonInput = ""
for line in sys.stdin:
    jsonInput += line

jsonObj = json.loads (jsonInput)

# debug
# print "Plugin executed, parameters:"
# print "type       = " + jsonObj["type"]
# print "action     = " + jsonObj["action"]

if jsonObj["type"]  != "alarm":
    print "This plugin only supports 'alarm' events, exiting..."
    sys.exit(0)

# update (this plugin does nothing for now...)
if jsonObj["action"] == "update":
    print "Not creating ticket as type is not new (type is " + jsonObj["type"] + ")"
    sys.exit(0)

jsonRequest = {}
# for authenticating
jsonRequest["service_key"]  = restapikey
# to identify a specific alarm
jsonRequest["incident_key"] = jsonObj["alarm"]["id"]

if jsonObj["action"] == "new":
    # http://developer.pagerduty.com/documentation/integration/events/trigger
    jsonRequest["event_type"]   = "trigger"
    jsonRequest["description"]  = jsonObj["alarm"]["name"]
    # append the msg to description when not empty (this may happens only for tests)
    if jsonObj["alarm"]["message"] != "":
        jsonRequest["description"] += " " + jsonObj["alarm"]["message"]
    jsonRequest["client"]       = "ClusterControl Monitor"
    # lets construct the clustercontrol web ui URL here
    jsonRequest["client_url"]   = "http://" + jsonObj["cmon_hostname"] + "/clustercontrol/";

    details = {}
    details["severity"]         = jsonObj["alarm"]["severity"]
    details["recommendation"]   = jsonObj["alarm"]["recommendation"]
    # append hostname if set in the alarm
    if "hostname" in jsonObj["alarm"] and jsonObj["alarm"]["hostname"] != "":
        details["hostname"]     = jsonObj["alarm"]["hostname"]

    jsonRequest["details"]      = details
elif jsonObj["action"] == "remove":
    # http://developer.pagerduty.com/documentation/integration/events/resolve
    jsonRequest["event_type"]   = "resolve"
    jsonRequest["description"]  = "The issue has been resolved."
    jsonRequest["details"]      = ""
else:
    print "ERROR: unkown/unsupported action: " + jsonObj["action"];
    sys.exit(1)

# debug
print "PUT request to " + resteventurl
print "JSon: " + json.dumps(jsonRequest)
# http://developer.pagerduty.com/documentation/integration/events/trigger
#
# NOTE: enable this if you want to test
# doc on event triggering:
# 
# but i disabled it for now to avoid too much reports during test-runs
#request = requests.put(resteventurl, data=json.dumps(jsonRequest))

