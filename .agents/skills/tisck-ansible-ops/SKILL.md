---
name: tisck-ansible-ops
description: "Operational guidance for administering, deploying, verifying, and recovering the TISCK tactical situational awareness platform via Ansible. Use when managing TISCK infrastructure stacks."
category: devops
tags: [tisck, tak, cloudtak, authentik, garage-s3, mediamtx, situational-awareness, horn-of-africa]
version: 1.0.0
---

# TISCK Platform Ansible Operations AI Skill

This skill guides the AI agent when operating, deploying, debugging, or extending the TISCK (Tactical Intelligence and Secure Communication Kit) Ansible automation codebase.

---

## Architecture Context

TISCK is an offline-first tactical infrastructure platform composed of 5 decoupled modules:
1. **`garage-infra`**: Single-node Garage S3 v2.4.1 object store (buckets: `cloudtak`, `tisck-basemaps`, `tak-server`, `tisck-assets`).
2. **`auth-infra`**: Self-hosted Authentik 2024.12 IdP with Redis task cache, PostgreSQL, and optional LDAP outpost.
3. **`media-infra`**: MediaMTX 1.11.3-ffmpeg tactical video streaming (RTSP, WebRTC, RTMP).
4. **`cloudtak`**: Situational awareness map (pure upstream branding), REST API, PostGIS, PMTiles tile server, and ETL workers.
5. **`tak-infra`**: Official TAK Server container stack (5.6/5.7) with isolated database, CoT TLS, and Marti v2 certificate auto-enrollment.

All modules interconnect via the shared external Docker bridge network **`tisck-net`** while maintaining strict database isolation on internal module networks.

---

## Operational Workflows

### 1. Full Platform Deployment
```bash
# Deploy to hosts listed in inventory
make deploy
# Or directly:
ansible-playbook -i inventory/hosts.ini playbooks/site.yml

# Deploy to local standalone host
make deploy-local
```

### 2. Selective Subsystem Execution (Tags)
```bash
# Storage only (Garage S3 cluster layout & bucket provisioning)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags garage

# Identity only (Authentik, tactical groups & OIDC provider setup)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags auth

# Media streaming only (MediaMTX)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags media

# Situational awareness core only (CloudTAK Web UI, PostGIS, Tiles)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags cloudtak

# TAK Server core only
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags tak_server
```

### 3. Health & Compliance Verification
```bash
# Execute deep healthcheck across all containers and ports
make check
# Or:
ansible-playbook -i inventory/hosts.ini playbooks/healthcheck.yml
```
Verify the following port security constraints:
- Public mesh ports (`0.0.0.0`): `5000` (API), `5002` (Tiles), `8089` (CoT TLS), `8443` (TAK Admin), `8446` (Cert Enrollment), `8554` (RTSP), `8889` (WebRTC), `1935` (RTMP).
- Private ports (`127.0.0.1` only): `3900` (S3 API), `3903` (Garage Admin), `9000` (Authentik), `389` (LDAP), `5432` (PostGIS), `9997` (Media API).

### 4. Lifecycle Management
Always stop and restart modules respecting dependency order:
```bash
make status                       # Inspect running state of all containers
make restart                      # Safely restart all modules in sequence
make stop                         # Safely stop all services
make start                        # Start all services
```

### 5. Backup & Disaster Recovery
```bash
# Generate timestamped backup archive in /var/backups/tisck/
make backup

# Restore a node from backup tarball
ansible-playbook -i inventory/hosts.ini playbooks/restore.yml \
  -e backup_file=/var/backups/tisck/tisck_backup_YYYYMMDD_HHMMSS.tar.gz
```

### 6. ATAK Client Onboarding
```bash
# Display ATAK certificate enrollment QR and connection parameters
make qr
```
