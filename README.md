# TISCK — Tactical Intelligence and Secure Communication Kit
## Enterprise Ansible Automation & Infrastructure Platform

[![Ansible](https://img.shields.io/badge/Ansible-2.15+-EE0000.svg?logo=ansible&logoColor=white)](https://ansible.com)
[![Docker](https://img.shields.io/badge/Docker-Engine_26+-2496ED.svg?logo=docker&logoColor=white)](https://docker.com)
[![Compose](https://img.shields.io/badge/Compose-V2-2496ED.svg?logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![Air--Gapped](https://img.shields.io/badge/Deployment-Air--Gapped_Ready-brightgreen.svg)](#offline--air-gapped-deployment)
[![Coverage](https://img.shields.io/badge/Coverage-Horn_of_Africa-006600.svg)](#horn-of-africa-geospatial-baseline)

This repository provides an automated, production-grade Ansible platform for provisioning, configuring, and operating the **TISCK (Tactical Intelligence and Secure Communication Kit)** deployment stack ([github.com/dawit1989/TISCK](https://github.com/dawit1989/TISCK.git)).

---

## Architecture Overview

TISCK delivers an offline-first, sovereign situational awareness and Cursor-on-Target (CoT) tracking infrastructure. It orchestrates 5 sovereign decoupled modules over a shared external Docker backbone network (`tisck-net`):

```
                    ┌───────────────────────────────────────────────┐
                    │  Field Devices (ATAK, WinTAK, Web Operators)  │
                    └───────────────────────┬───────────────────────┘
                                            │ LAN / Tactical Mesh (0.0.0.0)
   ═════════════════════════════════════════╪═════════════════════════════════════════════════════
   Shared External Backbone Network: tisck-net (Bridge)
   ─────────────────────────────────────────────────────────────────────────────────────────────
     │                         │                        │                       │
     ▼                         ▼                        ▼                       ▼
   ┌─────────────────────────┐ ┌──────────────────────┐ ┌─────────────────────┐ ┌────────────────┐
   │ cloudtak                │ │ garage-infra         │ │ media-infra         │ │ tak-infra      │
   │                         │ │                      │ │                     │ │                │
   │ • cloudtak-api (:5000)  │ │ • garage (:3900)     │ │ • mediamtx          │ │ • tak-server   │
   │ • cloudtak-tiles (:5002)│ │   (S3 API / Range)   │ │   (:8554 RTSP,      │ │   (:8089 CoT,  │
   │ • events / retention    │ │                      │ │    :8889 WebRTC,    │ │    :8443 Web,  │
   └───────────┬─────────────┘ └──────────────────────┘ │    :1935 RTMP)      │ │    :8446 Cert) │
               │                                        └─────────────────────┘ └───────┬────────┘
               │                                                                        │
               │                       ┌────────────────────────────────────────┐       │
               │                       │ auth-infra                             │       │
               │                       │                                        │       │
               │                       │ • authentik-server (:9000)             │       │
               │                       │ • authentik-ldap (:389, :636)          │◀──────┘
               │                       └───────────────────┬────────────────────┘
               │                                           │
   ════════════╪═══════════════════════════════════════════╪════════════════════════════════════
   Isolated Module Internal Networks (Strict Database Partitioning)
   ─────────────────────────────────────────────────────────────────────────────────────────────
               ▼                                           ▼                            ▼
   ┌─────────────────────────┐         ┌──────────────────────────────────────┐ ┌───────────────┐
   │ cloudtak-internal       │         │ auth-internal                        │ │ tak-internal  │
   │ • postgis (:5432)       │         │ • auth-db (PostgreSQL :5432)         │ │ • tak-db      │
   │                         │         │ • auth-cache (Redis :6379)           │ │   (:5432)     │
   └─────────────────────────┘         └──────────────────────────────────────┘ └───────────────┘
```

---

## Network Interface & Port Security Matrix

The Ansible roles enforce strict boundary isolation in accordance with **ADR 0006**:

| Module | Service Container | Host Binding | Access Scope | Ports & Protocol | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`cloudtak`** | `api` | `0.0.0.0:5000` | Tactical LAN / Mesh | TCP 5000 | Web situational awareness map, REST API, WebSocket CoT |
| **`cloudtak`** | `tiles` | `0.0.0.0:5002` | Tactical LAN / Mesh | TCP 5002 | PMTiles vector & raster map tile server |
| **`cloudtak`** | `postgis` | `127.0.0.1:5432` | Local Host / Internal | TCP 5432 | Isolated PostGIS geospatial database (`gis`) |
| **`garage-infra`** | `garage` | `127.0.0.1:3900` | Local Host / `tisck-net` | TCP 3900 | S3 object storage API (proxied via API/Tiles) |
| **`garage-infra`** | `garage` | `127.0.0.1:3903` | Local Host Only | TCP 3903 | Cluster layout administration |
| **`auth-infra`** | `authentik-server`| `127.0.0.1:9000` | Local Host / `tisck-net` | TCP 9000, 9443 | Identity provider Admin UI & OIDC endpoints |
| **`auth-infra`** | `authentik-ldap` | `127.0.0.1:389` | Local Host / `tisck-net` | TCP 389, 636 | Optional LDAP outpost directory bridge for TAK Server |
| **`auth-infra`** | `auth-db`, `auth-cache` | None (Internal) | `auth-internal` only | TCP 5432, 6379 | Dedicated identity database & Redis task cache |
| **`media-infra`** | `mediamtx` | `0.0.0.0:8554` | Tactical LAN / Mesh | TCP/UDP 8554 | Drone and bodycam video ingestion (RTSP) |
| **`media-infra`** | `mediamtx` | `0.0.0.0:8889` | Tactical LAN / Mesh | TCP 8889 | Low-latency WebRTC browser video playback |
| **`media-infra`** | `mediamtx` | `0.0.0.0:1935` | Tactical LAN / Mesh | TCP 1935 | RTMP & HLS streaming |
| **`tak-infra`** | `tak-server` | `0.0.0.0:8089` | Tactical LAN / Mesh | TCP 8089 | Cursor-on-Target TLS stream (ATAK/WinTAK) |
| **`tak-infra`** | `tak-server` | `0.0.0.0:8443` | Tactical LAN / Mesh | TCP 8443 | TAK Server Web Administration console |
| **`tak-infra`** | `tak-server` | `0.0.0.0:8446` | Tactical LAN / Mesh | TCP 8446 | Marti v2 client certificate auto-enrollment |
| **`tak-infra`** | `tak-db` | None (Internal) | `tak-internal` only | TCP 5432 | Independent TAK Server PostGIS database |

---

## Horn of Africa Geospatial Baseline

The automation baseline configures CloudTAK for offline tactical operations centered on **Addis Ababa** with bounding coverage covering the entire **Horn of Africa**:
- **Center**: `38.7578°E, 9.0222°N` (Zoom level: 6)
- **Bounding Box**:
  - Southwest: `32.9°E, 3.3°N` (South Sudan / Kenya border)
  - Northeast: `48.0°E, 15.0°N` (Eritrea / Red Sea / Somalia coast)
- **PMTiles Ingestion**: Integrated `basemaps` role allows zero-touch upload of `ethiopia.pmtiles` and regional layers directly into Garage S3 storage.

---

## Project Structure

```text
tisck-ansible/
├── ansible.cfg                          # Ansible global engine settings & pipelining
├── Makefile                             # Single-command operator workflows
├── README.md                            # Complete architecture & deployment guide
├── inventory/
│   ├── hosts.ini                        # Inventory defining local & remote nodes
│   └── group_vars/
│       └── all.yml                      # Centralized variables, ports, credentials, and toggles
├── playbooks/
│   ├── site.yml                         # Master end-to-end deployment playbook
│   ├── deploy.yml                       # Modular component deployment with tags
│   ├── healthcheck.yml                  # System health check, container status & port audit
│   ├── service_control.yml              # Unified service control (start, stop, restart, status)
│   ├── backup.yml                       # Automated database dumps & config snapshots
│   ├── restore.yml                      # Disaster recovery & database restoration runbook
│   └── tak_pairing_qr.yml               # ATAK client certificate enrollment QR generator
├── roles/
│   ├── common/                          # OS prep, ulimits, kernel sysctls, firewall (UFW)
│   ├── docker/                          # Docker CE & Compose V2 plugin, daemon log limits
│   ├── tisck_repo/                      # Git sync (or air-gapped bundle extraction) & permissions
│   ├── tisck_network/                   # Idempotent creation of shared 'tisck-net' bridge
│   ├── garage/                          # Single-node Garage S3 v2.4.1 layout & bucket provisioning
│   ├── auth/                            # Authentik 2024.12 IdP, secrets, groups & OIDC provider setup
│   ├── media/                           # MediaMTX video streaming engine configuration
│   ├── cloudtak/                        # CloudTAK Web COP, REST API, PostGIS & PMTiles tile server
│   ├── tak_server/                      # Official TAK Server container, DB & LDAP integration
│   └── basemaps/                        # Offline PMTiles basemap ingestion into Garage S3
└── scripts/
    └── quickstart.sh                    # One-step target host bootstrap script
```

---

## Quickstart

### Prerequisites
- Target host OS: **Ubuntu 22.04/24.04 LTS**, **Debian 12**, or **Rocky Linux 9**.
- Management control node with Ansible 2.15+ installed.

### 1. Configure Inventory
Edit `inventory/hosts.ini` to define your target node:
```ini
[tisck_servers]
tactical-node-01 ansible_host=192.168.1.100 ansible_user=ubuntu
```

Or deploy directly on the target machine using the `local` connection:
```ini
[local]
localhost ansible_connection=local ansible_python_interpreter=/usr/bin/python3
```

### 2. Configure Site Parameters
Review and customize passwords and network addresses in `inventory/group_vars/all.yml`:
```yaml
tisck_public_host_or_ip: "192.168.1.100"  # LAN / mesh IP of your edge node
authentik_bootstrap_password: "YourSecretAdminPassword!"
tak_ca_password: "YourTacticalCAPassword!"
```

### 3. Deploy Platform
Run the master playbook:
```bash
# Using Makefile:
make deploy

# Or standard Ansible command:
ansible-playbook -i inventory/hosts.ini playbooks/site.yml
```

For direct local deployment on a standalone tactical box:
```bash
make deploy-local
# Or:
bash scripts/quickstart.sh local
```

---

## Selective & Modular Deployment

You can deploy or update specific subsystems using Ansible tags:

```bash
# Storage only (Garage S3 layout and bucket provisioning)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags garage

# Identity only (Authentik, Redis, PostgreSQL, OIDC client)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags auth

# Media streaming only (MediaMTX)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags media

# Situational Awareness core only (CloudTAK, Tiles, PostGIS)
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags cloudtak

# TAK Server only
ansible-playbook -i inventory/hosts.ini playbooks/deploy.yml --tags tak_server
```

---

## Day-2 Operations & Platform Management

### 1. System Healthcheck & Audit
Verify the running status of all containers, listening ports, S3 bucket listings, and OIDC discovery endpoints:
```bash
make check
# Or:
ansible-playbook -i inventory/hosts.ini playbooks/healthcheck.yml
```

### 2. Service Lifecycle Control
Safely control all 5 modules respecting reverse/forward dependency order:
```bash
make status                       # Inspect running state of all containers
make restart                      # Safely restart all modules in sequence
make stop                         # Safely stop all services
make start                        # Start all services
```

### 3. Automated Database & Config Backup
Generate a timestamped snapshot containing dumps of all 3 databases (`gis`, `authentik`, `takserver`), certificate volumes, and environment secrets:
```bash
make backup
# Backup archives are written to /var/backups/tisck/tisck_backup_YYYYMMDD_HHMMSS.tar.gz
```

### 4. Disaster Recovery & Restoration
To restore a damaged or relocated tactical server from a backup tarball:
```bash
ansible-playbook -i inventory/hosts.ini playbooks/restore.yml \
  -e backup_file=/var/backups/tisck/tisck_backup_20261026_120000.tar.gz
```

### 5. ATAK Client Onboarding
Display the server parameters and auto-enrollment connection details for operator devices:
```bash
make qr
# Or:
ansible-playbook -i inventory/hosts.ini playbooks/tak_pairing_qr.yml
```

---

## Offline & Air-Gapped Deployment

In field environments with zero internet access:
1. Pre-package the TISCK repository into an archive (e.g. `tisck-source.tar.gz`).
2. In `inventory/group_vars/all.yml`, configure:
   ```yaml
   tisck_use_local_src: true
   tisck_local_src_path: "/path/to/tisck-source.tar.gz"
   ```
3. Pre-load pinned container images onto the target node using `docker load`:
   - `dxflrs/garage:v2.4.1`
   - `ghcr.io/goauthentik/server:2024.12.3`
   - `ghcr.io/goauthentik/ldap:2024.12.3`
   - `redis:7.4-alpine`
   - `postgres:16-alpine`
   - `postgis/postgis:17-3.4-alpine`
   - `postgis/postgis:17-3.5`
   - `bluenviron/mediamtx:1.11.3-ffmpeg`
4. In `inventory/group_vars/all.yml`, set `cloudtak_build_images: false` and `tak_build_images: false` if images were pre-built.
5. Execute `make deploy-local`.

---

## License & Sovereignty

- Base Repository: [dawit1989/TISCK](https://github.com/dawit1989/TISCK.git)
- Automation Platform: Maintained for sovereign and air-gapped tactical deployments.
