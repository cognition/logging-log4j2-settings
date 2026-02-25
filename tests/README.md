# Log Verification Tests

Tests verify that logging captures the right events per [Requirements.md](../Requirements.md).

## Requirements Coverage

| Requirement | Test File | What's Verified |
|-------------|-----------|-----------------|
| CRUD activities (successful/unsuccessful) | test_hdfs_audit_logs.py | HDFS audit logs ls, mkdir, rm with user, cmd, paths |
| Program initiations (direct, API/SDK) | test_spark_program_initiation.py | Spark audit, YARN application logs |
| Starting/end time for user access | test_ui_access_logs.py | Jetty access logs for UI requests |
| Node identification (hostname prefix) | test_log_format_and_metrics.py | [hostname] prefix in audit and access logs |
| Metrics output | test_log_format_and_metrics.py | hadoop-metrics2 FileSink, Spark Prometheus |

## Prerequisites

- Docker Compose stack running: `docker compose up -d`
- Wait 3–5 min for services to be healthy
- Python 3.12 with pytest: `pip install -r requirements-test.txt`

## Run Tests

```bash
# From repo root
pytest tests/ -v

# Run specific test file
pytest tests/test_hdfs_audit_logs.py -v

# Skip if cluster not running (tests auto-skip)
pytest tests/ -v
```

Tests that require the cluster will be skipped if `docker compose ps` shows the stack is not up.
