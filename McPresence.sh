#!/bin/bash
#
# McPresence.sh - cheap & easy presence detection
#
# Reads known persons' personal mobile device's MAC address
# against the localhost's DHCP leases
# to check each person's presence.
#
# Then sends each person's presence to an Openhab instance
#
# The dhcp-lease-list command is part of the ISC DHCP server's package 
# For other DHCP servers, maybe use libtext-dhcpleases-perl instead
#
# The personal_mobile_devices file takes two columns: MAC address and person
# MAC address must be lowercase - matching is case sensitive. Example:
# 7c:2f:80:0d:3b:a6 Alice
# 55:55:55:55:55:55 Bob
#
# The people's presence in Openhab is modeled as switches
# which are Openhab items recorded in /etc/openhab2/items
# and whose state attribute can be ON or OFF
# For example, here is the content of a /etc/openhab2/items/people.items
# Switch Alice
# Switch Bob
#
# This script is meant to be called from crontab - every minute is adequate.
#
# Absence detection requires DHCP lease expiration - by default ten minutes in ISC DHCP

# Openhab parameters
OH_IP=10.9.0.3
OH_port=80
OH_user=leases
OH_pass=password

# This script ships with the Debian default path for dhcp-lease-list - edit if your distribution differs
dhcp_lease_list="/usr/sbin/dhcp-lease-list"

# The script's directory - where personal_mobile_devices
# must also be found
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

leases=($($dhcp_lease_list --parsable | awk -F" "  '{print($2)}'))

IFS=$'\n'
for personal_mobile_device in `cat $DIR/personal_mobile_devices`

do
	MAC=`echo $personal_mobile_device | awk '{print($1)}'`
	person=`echo $personal_mobile_device | awk '{print($2)}'`
	if [[ " ${leases[@]} " =~ " ${MAC} " ]]; then
		# Present
		curl -X POST -d "ON" -H "Content-Type: text/plain" \
		http://$OH_user:$OH_pass@$OH_IP:$OH_port/rest/items/$person
	else
		# Absent
		curl -X POST -d "OFF" -H "Content-Type: text/plain" \
		http://$OH_user:$OH_pass@$OH_IP:$OH_port/rest/items/$person
	fi
done

