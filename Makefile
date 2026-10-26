# ==============================================================================
# TISCK Tactical Platform - Ansible Operations Makefile
# ==============================================================================

INVENTORY ?= inventory/hosts.ini

.PHONY: all deploy deploy-local check status start stop restart backup qr help

help:
	@echo "TISCK Ansible Management Commands:"
	@echo "  make deploy         - Deploy full TISCK stack to inventory hosts"
	@echo "  make deploy-local   - Deploy full TISCK stack on local host"
	@echo "  make check          - Run comprehensive healthcheck and audit"
	@echo "  make status         - Query status of all container services"
	@echo "  make start          - Start all TISCK services in dependency order"
	@echo "  make stop           - Stop all TISCK services safely"
	@echo "  make restart        - Restart all TISCK services"
	@echo "  make backup         - Perform coordinated database and config snapshot"
	@echo "  make qr             - Display ATAK client pairing info"

deploy:
	ansible-playbook -i $(INVENTORY) playbooks/site.yml

deploy-local:
	ansible-playbook -i $(INVENTORY) -l local playbooks/site.yml

check:
	ansible-playbook -i $(INVENTORY) playbooks/healthcheck.yml

status:
	ansible-playbook -i $(INVENTORY) playbooks/service_control.yml -e tisck_action=status

start:
	ansible-playbook -i $(INVENTORY) playbooks/service_control.yml -e tisck_action=start

stop:
	ansible-playbook -i $(INVENTORY) playbooks/service_control.yml -e tisck_action=stop

restart:
	ansible-playbook -i $(INVENTORY) playbooks/service_control.yml -e tisck_action=restart

backup:
	ansible-playbook -i $(INVENTORY) playbooks/backup.yml

qr:
	ansible-playbook -i $(INVENTORY) playbooks/tak_pairing_qr.yml
