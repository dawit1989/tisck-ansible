#!/usr/bin/env bash
# ==============================================================================
# TISCK Ansible Quickstart Bootstrap Script
# ==============================================================================
set -euo pipefail

echo "================================================================="
echo "  TISCK Tactical Platform - Ansible Deployment Bootstrap         "
echo "================================================================="

# Detect OS and install Ansible if missing
if ! command -v ansible-playbook >/dev/null 2>&1; then
    echo "[+] Installing Ansible prerequisites..."
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y software-properties-common curl git python3 python3-pip
        sudo apt install -y ansible
    elif [ -f /etc/redhat-release ]; then
        sudo dnf install -y epel-release
        sudo dnf install -y ansible git python3 python3-pip
    fi
fi

# Install required Ansible Galaxy collections
echo "[+] Installing Ansible Galaxy collections (community.docker, ansible.posix)..."
ansible-galaxy collection install community.docker ansible.posix community.general --upgrade

# Execute deployment
TARGET="${1:-local}"
echo "[+] Executing TISCK deployment for target: ${TARGET}..."
if [ "$TARGET" = "local" ]; then
    ansible-playbook -i inventory/hosts.ini -l local playbooks/site.yml
else
    ansible-playbook -i inventory/hosts.ini playbooks/site.yml
fi

echo "================================================================="
echo "  TISCK Platform Successfully Provisioned!"
echo "================================================================="
