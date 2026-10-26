---
name: ansible
description: "Expert guidance for automating infrastructure with Ansible: playbooks, roles, inventories, modules, idempotency, testing, and vault management. Use when writing, debugging, or executing Ansible automation."
category: devops
tags: [ansible, automation, playbooks, roles, inventory, idempotency, devops, iac]
version: 1.0.0
---

# Ansible Expert AI Skill

This skill provides expert instructions, architectural patterns, and guardrails for authoring, maintaining, and executing Ansible infrastructure-as-code automation.

---

## When to Use This Skill

Activate this skill whenever:
- Designing, writing, or refactoring Ansible playbooks, roles, handlers, or templates.
- Configuring inventories (`hosts.ini`, dynamic inventories, `group_vars`, `host_vars`).
- Debugging task failures, connection errors, or variable interpolation issues.
- Enforcing idempotency, state convergence, and security guardrails.
- Managing sensitive data with Ansible Vault.
- Validating and linting automation (`ansible-playbook --syntax-check`, `ansible-lint`).

---

## Core Engineering Principles

### 1. Modern Syntax & Fully Qualified Collection Names (FQCN)
Always use Fully Qualified Collection Names rather than legacy short module names:
- Prefer `ansible.builtin.copy`, `ansible.builtin.template`, `ansible.builtin.apt`, `ansible.builtin.systemd`
- For Docker: `community.docker.docker_container`, `community.docker.docker_network`
- For POSIX / Linux: `ansible.posix.sysctl`, `ansible.posix.firewalld`

### 2. Strict Idempotency Standards
Every task must converge safely to the desired state without producing false changes:
- Avoid raw shell/command modules when a dedicated module exists.
- When `ansible.builtin.command` or `ansible.builtin.shell` is unavoidable, explicitly define:
  - `changed_when`: A boolean expression that evaluates to true only when a genuine mutation occurred.
  - `failed_when`: Custom failure conditions.
  - `creates` or `removes`: File presence checks to skip unnecessary executions.

### 3. Role Directory Hierarchy
Maintain the canonical Ansible role architecture:
```text
roles/<role_name>/
├── tasks/
│   └── main.yml        # Primary task execution list
├── handlers/
│   └── main.yml        # Event handlers triggered by notify
├── templates/
│   └── *.j2            # Jinja2 configuration templates
├── files/              # Static files transferred unmodified
├── defaults/
│   └── main.yml        # Lowest-precedence default variables (overridable)
├── vars/
│   └── main.yml        # High-precedence role-internal variables
└── meta/
    └── main.yml        # Role dependencies and metadata
```

### 4. Thin Playbooks, Rich Roles
- Playbooks should orchestrate high-level host groups, role assignments, tags, and pre/post tasks.
- All implementation logic, configuration templates, and conditional flows belong in dedicated roles.

### 5. Variable Scoping & Precedence
- Centralize environment-wide defaults in `inventory/group_vars/all.yml`.
- Place host-specific customizations in `inventory/host_vars/<hostname>.yml`.
- Role defaults (`roles/<role>/defaults/main.yml`) should specify safe baseline values.
- Never hardcode IP addresses, credentials, or host-specific paths directly in tasks.

---

## Validation & Operational Commands

### Syntax & Dry Run Checks
```bash
# Verify playbook syntax without contacting hosts
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --syntax-check

# Run in check mode (dry-run without applying changes)
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --check --diff

# Target specific hosts or tags
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --limit tisck_servers --tags common,docker
```

### Connectivity & Ad-Hoc Management
```bash
# Test host connectivity
ansible -i inventory/hosts.ini all -m ping

# Inspect target host facts
ansible -i inventory/hosts.ini all -m setup -a "filter=ansible_default_ipv4"
```

### Secret Management (Ansible Vault)
```bash
# Encrypt a sensitive variables file
ansible-vault encrypt inventory/group_vars/vault.yml

# Edit encrypted secrets in place
ansible-vault edit inventory/group_vars/vault.yml

# Execute playbook supplying vault password
ansible-playbook -i inventory/hosts.ini playbooks/site.yml --ask-vault-pass
```
