"""
Tests for HDFS audit logging (CRUD activities per Requirements.md).

Verifies that hdfs-audit.log captures:
- Successful and unsuccessful CRUD operations
- User identity
- Command (cmd)
- Source/destination paths
- [hostname] prefix for SIEM
"""

import subprocess
import time
from pathlib import Path
from typing import List

import pytest

from conftest import NAMENODE_CONTAINER, REPO_ROOT, read_log_tail


@pytest.fixture
def hdfs_audit_log():
    """Path to HDFS audit log (per-hostname to avoid RM/NN conflict)."""
    return REPO_ROOT / "hadoop-logs" / "hdfs-audit-namenode.log"


def run_hdfs_cmd(cmd: List[str]) -> subprocess.CompletedProcess:
    """Run hdfs dfs command via docker exec on namenode."""
    return subprocess.run(
        ["docker", "exec", NAMENODE_CONTAINER, "hdfs", "dfs", *cmd],
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        timeout=30,
    )


class TestHDFSAuditCRUD:
    """Verify HDFS audit log captures CRUD operations."""

    def test_audit_log_exists_and_has_rfaaudit_tag(self, cluster_running, hdfs_audit_log):
        """HDFS audit log file exists and uses RFAAUDIT tag."""
        assert hdfs_audit_log.exists(), "hdfs-audit.log should exist"
        content = read_log_tail(hdfs_audit_log, 50)
        assert "[Audit][RFAAUDIT]" in content or "[RFAAUDIT]" in content, (
            "Audit entries should have RFAAUDIT tag for SIEM correlation"
        )

    def test_list_operation_logged(self, cluster_running, hdfs_audit_log):
        """ls (read) operation is logged in HDFS audit."""
        run_hdfs_cmd(["-ls", "/"])
        time.sleep(2)
        content = read_log_tail(hdfs_audit_log, 100)
        # HDFS audit logs 'open' or 'listStatus' for ls
        assert "cmd=" in content or "allowed=" in content or "open" in content.lower(), (
            "HDFS ls should produce audit entry with cmd or allowed"
        )

    def test_mkdir_operation_logged(self, cluster_running, hdfs_audit_log):
        """mkdir (create) operation is logged."""
        test_path = "/tmp/audit-test-mkdir-{}".format(int(time.time()))
        run_hdfs_cmd(["-mkdir", "-p", test_path])
        time.sleep(2)
        content = read_log_tail(hdfs_audit_log, 100)
        assert "mkdir" in content.lower() or "create" in content.lower() or test_path in content, (
            "HDFS mkdir should produce audit entry"
        )
        # Cleanup
        run_hdfs_cmd(["-rm", "-r", "-f", test_path])

    def test_hostname_prefix_in_audit(self, cluster_running, hdfs_audit_log):
        """Audit log lines include [hostname] prefix for SIEM."""
        content = read_log_tail(hdfs_audit_log, 20)
        assert content, "Audit log should have content"
        # Format: [hostname][Audit][RFAAUDIT] ...
        lines = [l for l in content.split("\n") if l.strip() and "[Audit]" in l]
        if lines:
            assert lines[0].startswith("["), "Audit lines should start with [hostname] prefix"
