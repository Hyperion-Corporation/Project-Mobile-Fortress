# ansible/

> **Optional.** Config-management/provisioning for the optional backend on
> bare-metal or VM targets outside the Kubernetes/container world (e.g. a
> bastion host, a self-hosted CI runner). Not needed if everything runs in
> containers/k8s, or if your game is offline-only — delete this directory in
> that case.

```bash
ansible-playbook -i inventory/hosts.ini playbook.yml
```

| Path | Purpose |
| --- | --- |
| `ansible.cfg` | Local Ansible config (inventory path, SSH settings) |
| `inventory/hosts.ini` | Target hosts, grouped |
| `playbook.yml` | Entry-point playbook, applies the `app` role |
| `roles/app/` | Example role: installs and configures the backend on a host |
