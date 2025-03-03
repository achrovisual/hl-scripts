#!/bin/bash

source /opt/vyatta/etc/functions/script-template

if [ $# -ne 2 ]; then
  echo "Usage: $0 <firewall_name> <rule_number>"
  exit 1
fi

firewall_name="$1"
rule_number="$2"

if ! [[ "$rule_number" =~ ^[0-9]+$ ]]; then
  echo "Error: Rule number must be a positive integer."
  exit 1
fi

configure
set firewall name "$firewall_name" rule "$rule_number" disable
commit
save
exit