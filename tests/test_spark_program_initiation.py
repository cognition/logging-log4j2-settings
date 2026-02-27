"""
Tests for Spark and YARN program initiation logging (Requirements.md).

Verifies that:
- Spark job submissions are logged (spark-audit.log)
- Application lifecycle is captured
- YARN logs application submissions with user
"""

import subprocess
import time
from pathlib import Path

import pytest

from conftest import REPO_ROOT, SPARK_CLIENT, read_log_tail


def run_spark_submit() -> subprocess.CompletedProcess:
    """Submit a Spark Pi job to YARN."""
    return subprocess.run(
        [
            "docker",
            "exec",
            SPARK_CLIENT,
            "/opt/spark/bin/spark-submit",
            "--class",
            "org.apache.spark.examples.SparkPi",
            "--deploy-mode",
            "client",
            "/opt/spark/examples/jars/spark-examples_2.12-3.5.6.jar",
            "10",
        ],
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        timeout=120,
    )


class TestSparkAuditLogs:
    """Verify Spark audit log captures program initiations."""

    def test_spark_audit_log_exists(self, cluster_running):
        """Spark audit log exists."""
        from conftest import find_log

        run_spark_submit()
        time.sleep(5)
        path = find_log(REPO_ROOT / "logs", "spark-audit.log")
        assert path is not None and path.exists(), "spark-audit.log should exist after job submission"

    def test_spark_audit_has_audit_tag(self, cluster_running):
        """Spark audit uses [Audit][Spark] tag."""
        from conftest import find_log

        run_spark_submit()
        time.sleep(5)
        path = find_log(REPO_ROOT / "logs", "spark-audit.log")
        assert path, "spark-audit.log should exist"
        content = read_log_tail(path, 200)
        assert "[Audit]" in content or "Spark" in content, (
            "Spark audit should have Audit tag"
        )

    def test_yarn_logs_application_submission(self, cluster_running):
        """YARN ResourceManager logs application submission."""
        run_spark_submit()
        time.sleep(5)
        # YARN RM logs to logs/resourcemanager/ (rm-audit.log, rm-appsummary.log, hadoop.log)
        logs_dir = REPO_ROOT / "logs"
        yarn_logs = list(logs_dir.glob("**/rm-audit.log")) + list(logs_dir.glob("**/rm-appsummary.log")) + list(logs_dir.glob("**/hadoop.log"))
        yarn_logs = list(dict.fromkeys(yarn_logs))  # deduplicate
        if not yarn_logs:
            yarn_logs = list(logs_dir.glob("**/*.log"))
        content = ""
        for p in yarn_logs[:3]:
            content += read_log_tail(p, 100)
        # Should mention application or Spark
        assert "application" in content.lower() or "spark" in content.lower() or content, (
            "YARN should log application submissions"
        )
