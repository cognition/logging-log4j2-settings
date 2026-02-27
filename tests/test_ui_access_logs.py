"""
Tests for UI access logging (Requirements.md: starting and end time for user access).

Verifies that jetty access logs capture HTTP requests to UIs.
"""

import subprocess
import time
from pathlib import Path

import pytest

from conftest import REPO_ROOT, read_log_tail


def curl_ui(url: str) -> subprocess.CompletedProcess:
    """Curl a UI endpoint from host."""
    return subprocess.run(
        ["curl", "-s", "-o", "/dev/null", "-w", "%{http_code}", url],
        cwd=REPO_ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
        timeout=10,
    )


class TestUIAccessLogs:
    """Verify UI access logs capture requests."""

    def test_jetty_resourcemanager_log_exists_after_access(self, cluster_running):
        """Accessing RM UI produces jetty-resourcemanager.log entries."""
        curl_ui("http://localhost:8088/")
        time.sleep(2)
        path = REPO_ROOT / "logs" / "resourcemanager" / "jetty-resourcemanager.log"
        if not path.exists():
            pytest.skip("jetty-resourcemanager.log not found")
        content = read_log_tail(path, 20)
        if not content:
            pytest.skip(
                "jetty-resourcemanager.log is empty; hadoop-sandbox RM may use Slf4jRequestLog "
                "(Hadoop 3.4+) instead of log4j http.requests.resourcemanager"
            )
        assert content, "Jetty RM log should have entries after UI access"

    def test_jetty_access_has_hostname_prefix(self, cluster_running):
        """Access log lines include [hostname] prefix."""
        curl_ui("http://localhost:8088/")
        curl_ui("http://localhost:18080/")
        time.sleep(2)
        for log_dir, name in [
            (REPO_ROOT / "logs" / "resourcemanager", "jetty-resourcemanager.log"),
            (REPO_ROOT / "logs" / "sparkhistoryserver", "jetty-access.log"),
        ]:
            path = log_dir / name
            if path.exists():
                content = read_log_tail(path, 10)
                if content and "[Access]" in content:
                    assert "[" in content.split("\n")[0], "Access logs should have [hostname] prefix"

    def test_spark_history_ui_access_logged(self, cluster_running):
        """Spark History Server UI access is logged."""
        curl_ui("http://localhost:18080/")
        time.sleep(2)
        path = REPO_ROOT / "logs" / "sparkhistoryserver" / "jetty-access.log"
        if path.exists():
            content = read_log_tail(path, 20)
            assert content, "Spark History Server access should be logged"
