## Syslog Setup

This document explains how to forward Hadoop ecosystem logs to a remote syslog endpoint.

---

## 1. Configure Syslog Receiver

On the syslog host (which may be the same as the cluster host):

1. Enable a syslog input (e.g. UDP 514).
2. Route the desired facility (e.g. `LOCAL1`) to a dedicated file such as `/var/log/hadoop-logging/syslog.log`.

Example (rsyslog snippet):

```conf
module(load="imudp")
input(type="imudp" port="514")

local1.*    /var/log/hadoop-logging/syslog.log
```

---

## 2. Configure Environment

On the cluster host (or Docker Compose environment):

```bash
export SYSLOG_HOST=syslog.example.com
export SYSLOG_PORT=514
export SYSLOG_PROTOCOL=UDP
export SYSLOG_FACILITY=LOCAL1
```

These variables are consumed by:

- `hadoop-conf/log4j2-syslog.properties`
- `spark-conf/log4j2-syslog.properties`
- `docker-compose.syslog.yml` (and its Ansible template)

---

## 3. Enable Syslog in Docker Compose

Run:

```bash
docker compose -f docker-compose.yml -f docker-compose.syslog.yml up -d
```

This:

- Switches Hadoop daemons to `log4j2-syslog.properties`.
- Switches Spark daemons to `log4j2-syslog.properties`.
- Passes `SYSLOG_HOST`, `SYSLOG_PORT`, `SYSLOG_PROTOCOL`, and `SYSLOG_FACILITY` to the JVM.

Audit and access logs are then forwarded to the configured syslog endpoint in addition to being written to files under `logs/`.

---

## 4. Enable Syslog via Ansible

In `ansible/roles/hadoop_logging/defaults/main.yml`:

- `hadoop_logging_syslog_enabled: false`
- `syslog_host: localhost`
- `syslog_port: "514"`
- `syslog_protocol: UDP`
- `syslog_facility: LOCAL1`

Example playbook run:

```bash
ansible-playbook -i localhost, -c local \
  ansible/playbooks/deploy-logging.yml \
  -e hadoop_logging_syslog_enabled=true \
  -e syslog_host=syslog.example.com \
  -e syslog_port=514 \
  -e syslog_protocol=UDP \
  -e syslog_facility=LOCAL1
```

This generates `docker-compose.syslog.yml` at the deploy path using the template.

