## Logging Toggles

All Hadoop ecosystem logging components are **enabled by default**. The only toggle is whether to forward logs to a remote syslog endpoint.

---

## Always-On Logging

The following are always on:

- HDFS audit logging
- YARN ResourceManager audit logging
- YARN NodeManager audit logging
- MapReduce JobHistory audit logging
- MapReduce shuffle audit logging
- Spark audit logging
- Hive audit logging
- HTTP access logs for all web UIs

---

## Syslog Toggle

Remote log forwarding is controlled via syslog settings.

### Environment Variables

| Variable          | Description           | Default   |
|-------------------|-----------------------|-----------|
| `SYSLOG_HOST`     | Syslog host           | localhost |
| `SYSLOG_PORT`     | Syslog port           | 514       |
| `SYSLOG_PROTOCOL` | Protocol (`UDP/TCP`)  | UDP       |
| `SYSLOG_FACILITY` | Syslog facility       | LOCAL1    |

### Docker Compose

Use:

```bash
docker compose -f docker-compose.yml -f docker-compose.syslog.yml up -d
```

`docker-compose.syslog.yml` configures daemons to use `log4j2-syslog.properties` and pass syslog parameters.

### Ansible Role

The `hadoop_logging` role exposes:

- `hadoop_logging_syslog_enabled` — set to `true` to generate `docker-compose.syslog.yml`.
- `syslog_host`, `syslog_port`, `syslog_protocol`, `syslog_facility` — used in the template.

See `ansible/roles/hadoop_logging/defaults/main.yml` and `ansible/roles/hadoop_logging/templates/docker-compose-syslog-override.yml.j2`.

