## Ansible Role: `hadoop_logging`

The `hadoop_logging` role deploys logging-related configuration files to a target host.

---

## Defaults

See `ansible/roles/hadoop_logging/defaults/main.yml`.

Key variables:

- `log_dir` — log directory on target host (default `/logs`).
- `hadoop_logging_deploy_path` — path where configs are deployed.
- `hadoop_logging_config_source` — source path for configs (bundle root).
- `hadoop_logging_copy_configs` — whether to copy `hadoop-conf/` and `spark-conf/`.
- `hadoop_logging_syslog_enabled` — whether to generate a docker syslog override file.
- `hadoop_logging_docker_deploy` — whether the target uses Docker Compose.
- `syslog_host`, `syslog_port`, `syslog_protocol`, `syslog_facility` — syslog parameters.

---

## Tasks

See `ansible/roles/hadoop_logging/tasks/main.yml`.

The role:

1. Creates the deploy path and log directory.
2. Copies `hadoop-conf/` and `spark-conf/` from the bundle when `hadoop_logging_copy_configs` is true.
3. Generates `docker-compose.syslog.yml` from the template when:
   - `hadoop_logging_syslog_enabled` is true, and
   - `hadoop_logging_docker_deploy` is true.

---

## Playbook

`ansible/playbooks/deploy-logging.yml`:

```yaml
---
- name: Deploy Hadoop logging configuration
  hosts: localhost
  connection: local
  roles:
    - role: hadoop_logging
```

Run:

```bash
ansible-playbook -i localhost, -c local ansible/playbooks/deploy-logging.yml
```

Override variables as needed:

```bash
ansible-playbook -i localhost, -c local ansible/playbooks/deploy-logging.yml \
  -e hadoop_logging_syslog_enabled=true \
  -e hadoop_logging_docker_deploy=true \
  -e syslog_host=syslog.example.com
```

