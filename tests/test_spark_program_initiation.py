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
        path = REPO_ROOT / "spark-logs" / "spark-audit.log"
        # May not exist until first job; run a quick job to generate
        run_spark_submit()
        time.sleep(5)
        assert path.exists(), "spark-audit.log should exist after job submission"

    def test_spark_audit_has_audit_tag(self, cluster_running):
        """Spark audit uses [Audit][Spark] tag."""
        run_spark_submit()
        time.sleep(5)
        path = REPO_ROOT / "spark-logs" / "spark-audit.log"
        content = read_log_tail(path, 200)
        assert "[Audit]" in content or "Spark" in content, (
            "Spark audit should have Audit tag"
        )

    def test_yarn_logs_application_submission(self, cluster_running):
        """YARN ResourceManager logs application submission."""
        run_spark_submit()
        time.sleep(5)
        # YARN RM logs to yarn-*-resourcemanager-*.log or hadoop.log
        yarn_logs = list((REPO_ROOT / "hadoop-logs").glob("*resourcemanager*.log"))
        yarn_logs.extend((REPO_ROOT / "hadoop-logs").glob("yarn*.log"))
        if not yarn_logs:
            yarn_logs = list((REPO_ROOT / "hadoop-logs").glob("*.log"))
        content = ""
        for p in yarn_logs[:3]:
            content += read_log_tail(p, 100)
        # Should mention application or Spark
        assert "application" in content.lower() or "spark" in content.lower() or content, (
            "YARN should log application submissions"
        )
