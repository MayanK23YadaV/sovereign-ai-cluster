#!/bin/bash
echo "Starting global update across all Swarm nodes..."
ansible all -i /etc/ansible/hosts.ini -m apt -a "update_cache=yes upgrade=dist" -b

echo "Update complete. Sending shutdown signal to all worker nodes..."
ansible workers -i /etc/ansible/hosts.ini -m command -a "shutdown -h now" -b

echo "Workers shutting down. Shutting down Head Node..."
sleep 5
shutdown -h now
