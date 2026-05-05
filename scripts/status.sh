#!/bin/bash
ansible all -i /etc/ansible/hosts.ini -m shell -a '
  echo "----------------------------------------"
  echo "Hostname: $(hostname)"
  echo "Uptime:   $(uptime -p)"
  echo "RAM Used: $(free -m | awk "/Mem:/ {printf \"%.1fGB / %.1fGB\", \$3/1024, \$2/1024}")"
  echo "Disk Use: $(df -h / | awk "NR==2 {print \$5}")"
  if systemctl is-active --quiet llama-rpc; then echo "RPC:      ACTIVE"; else echo "RPC:      Head Node"; fi
  echo "----------------------------------------"
' | grep -v 'CHANGED' | grep -v 'rc=0' | grep -v 'WARNING'
