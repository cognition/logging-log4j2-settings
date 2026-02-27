## Log Tag Variables (`LOG_TAG_*`)

Log tags let you add extra context to every log line without changing application code. They are injected into log prefixes via Log4j 2 patterns.

---

## Standard Tags

| Variable              | Purpose                                        | Example                |
|-----------------------|-----------------------------------------------|------------------------|
| `LOG_TAG_HOSTNAME`    | Override hostname in log prefixes             | `nn-01.example.com`   |
| `LOG_TAG_APPLICATION` | Application or deployment name                | `[spark-hadoop]`      |
| `LOG_TAG_ACTION`      | Action/category (e.g. audit vs access)        | `[audit]`, `[access]` |
| `LOG_TAG_SECURITY`    | Security-related context                      | `[security]`          |
| `LOG_TAG_CUSTOM`      | Freeform, user-defined tag (or chain of tags) | `[school-is-fun]`     |

Tags are optional. If unset, they contribute nothing to the prefix.

---

## Where They Appear

Hadoop Log4j 2 pattern (simplified):

```properties
[${sys:log4j.hostname:-unknown}]${env:LOG_TAG_APPLICATION:-}${env:LOG_TAG_ACTION:-}${env:LOG_TAG_SECURITY:-}${env:LOG_TAG_CUSTOM:-} %d{ISO8601} %p %c{2}: %m%n
```

Spark Log4j 2 pattern:

```properties
[${env:LOG_TAG_HOSTNAME:-${env:HOSTNAME:-unknown}}]${env:LOG_TAG_APPLICATION:-}${env:LOG_TAG_ACTION:-}${env:LOG_TAG_SECURITY:-}${env:LOG_TAG_CUSTOM:-} %d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n%ex
```

Hive Log4j 2 pattern (appender examples):

```properties
[${env:LOG_TAG_HOSTNAME:-${env:HOSTNAME:-unknown}}]${env:LOG_TAG_APPLICATION:-}[Hive]${env:LOG_TAG_SECURITY:-}${env:LOG_TAG_CUSTOM:-} ...
[${env:LOG_TAG_HOSTNAME:-${env:HOSTNAME:-unknown}}]${env:LOG_TAG_APPLICATION:-}[Audit]${env:LOG_TAG_SECURITY:-}${env:LOG_TAG_CUSTOM:-} ...
```

---

## Examples

### Example 1 — Tagging by environment and application

```bash
export LOG_TAG_APPLICATION='[spark-hadoop]'
export LOG_TAG_CUSTOM='[dev]'
```

Resulting prefix:

```text
[namenode][spark-hadoop][dev] 2026-03-01T12:00:00,123 INFO ...
```

### Example 2 — Security-focused audit logs

```bash
export LOG_TAG_APPLICATION='[spark-hadoop]'
export LOG_TAG_ACTION='[audit]'
export LOG_TAG_SECURITY='[security]'
```

Resulting prefix:

```text
[resourcemanager][spark-hadoop][audit][security] 2026-03-01T12:00:00,123 INFO ...
```

### Example 3 — Custom campaign or experiment tag

```bash
export LOG_TAG_CUSTOM='[school-is-fun]'
```

Resulting prefix:

```text
[spark-client][school-is-fun] 26/03/01 12:00:00 INFO ...
```

