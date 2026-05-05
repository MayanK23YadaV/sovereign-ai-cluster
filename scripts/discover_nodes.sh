#!/bin/bash
# =============================================================================
# Sovereign AI Lab — DHCP Node Discovery Script
# Scans the campus network to find all cloned worker nodes and builds
# an Ansible inventory automatically.
#
# Usage: sudo bash /opt/scripts/discover_nodes.sh
# =============================================================================

set -e

# Use argument if provided, otherwise dynamically calculate local subnet
SUBNET="${1:-$(ip route | awk '/kernel/ {print $1}' | head -n 1)}"
HEAD_IP=$(hostname -I | awk '{print $1}')
INVENTORY="/etc/ansible/hosts.ini"
SSH_KEY="/root/.ssh/id_ed25519"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=3 -o BatchMode=yes -i $SSH_KEY"

echo "========================================"
echo "  SOVEREIGN AI LAB — NODE DISCOVERY"
echo "========================================"
echo "Head Node IP: $HEAD_IP"
echo "Scanning subnet: $SUBNET"
echo "========================================"
echo ""

# Step 1: Get credentials for the fresh installs
echo "Since you manually installed Mint, we need the default credentials you set"
echo "so we can automatically inject the SSH keys."
read -p "Enter the username you created on the workers (e.g., root or aiadmin): " SSH_USER
read -s -p "Enter the password you set for those workers: " SSH_PASS
echo
echo

echo "[1/4] Installing sshpass (if missing)..."
apt-get install -y sshpass &>/dev/null || true
echo ""

# Step 2: Fast network scan to find all live hosts with SSH open
echo "[2/4] Scanning network for live hosts with SSH (Port 22)..."
LIVE_IPS=$(nmap -p 22 --open --min-rate 1000 $SUBNET 2>/dev/null | grep "Nmap scan report" | awk '{print $NF}' | tr -d '()')
LIVE_COUNT=$(echo "$LIVE_IPS" | wc -w)
if [ -z "$LIVE_IPS" ]; then LIVE_COUNT=0; fi
echo "       Found $LIVE_COUNT hosts with SSH open."
echo ""

# Step 3: Filter — try to log in and drop the SSH key
echo "[3/4] Attempting to inject SSH keys into fresh workers..."
CLUSTER_IPS=()

for ip in $LIVE_IPS; do
    # Skip our own IP
    if [ "$ip" = "$HEAD_IP" ]; then
        echo "       $ip — SKIP (this is the head node)"
        continue
    fi

    # Try to copy the SSH key using sshpass
    sshpass -p "$SSH_PASS" ssh-copy-id -o StrictHostKeyChecking=no -i $SSH_KEY $SSH_USER@$ip &>/dev/null

    # Test if the key works now
    REMOTE_HOST=$(ssh $SSH_OPTS $SSH_USER@$ip "hostname" 2>/dev/null || echo "failed")

    if [ "$REMOTE_HOST" != "failed" ]; then
        echo "       $ip — ✅ CLUSTER NODE CONNECTED (hostname: $REMOTE_HOST)"
        CLUSTER_IPS+=("$ip")
    else
        echo "       $ip — ❌ Connection failed or wrong password (skipped)"
    fi
done

WORKER_COUNT=${#CLUSTER_IPS[@]}
echo ""
echo "       Successfully connected to $WORKER_COUNT worker nodes."
echo ""

if [ "$WORKER_COUNT" -eq 0 ]; then
    echo "[!] No worker nodes found."
    echo "    Make sure you installed 'openssh-server' on the fresh workers"
    echo "    and that the password you entered was correct."
    exit 1
fi

# Step 4: Sort IPs and assign node numbers
echo "[4/4] Assigning node numbers..."
IFS=$'\n' SORTED_IPS=($(sort -t . -k 4 -n <<<"${CLUSTER_IPS[*]}")); unset IFS

# Step 4: Generate Ansible inventory
echo "[4/4] Writing Ansible inventory to $INVENTORY"
echo ""

cat > $INVENTORY << HEADER
# =============================================================================
# Sovereign AI Lab — Auto-Generated Ansible Inventory
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
# Head Node: $HEAD_IP
# Workers Discovered: $WORKER_COUNT
# =============================================================================

[head]
node01 ansible_connection=local ansible_host=$HEAD_IP

[workers]
HEADER

NODE_NUM=2
for ip in "${SORTED_IPS[@]}"; do
    printf -v node_name "node%02d" $NODE_NUM
    echo "$node_name ansible_host=$ip" >> $INVENTORY
    echo "       $node_name → $ip"
    ((NODE_NUM++))
done

cat >> $INVENTORY << FOOTER

[workers:vars]
ansible_user=$SSH_USER
ansible_ssh_common_args=-o StrictHostKeyChecking=no

[cluster:children]
head
workers
FOOTER

echo ""
echo "========================================"
echo "  DISCOVERY COMPLETE"
echo "========================================"
echo "  Head Node:  node01 ($HEAD_IP)"
echo "  Workers:    $WORKER_COUNT nodes discovered"
echo "  Total:      $((WORKER_COUNT + 1)) nodes in cluster"
echo "  Inventory:  $INVENTORY"
echo ""
echo "  Next step:"
echo "  ansible-playbook -i $INVENTORY /etc/ansible/cluster_init.yml"
echo "========================================"
