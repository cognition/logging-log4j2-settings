"""
Pytest configuration and fixtures for log verification tests.

Verifies that logging captures the right events per Requirements.md:
- CRUD activities (HDFS audit)
- Program initiations (Spark, YARN)
- UI access (jetty logs)
- Hostname prefix for SIEM correlation
- Metrics output
"""

import json
import os
import subprocess
import time
from pathlib import Path

import pytest

# Paths relative to repo root
REPO_ROOT = Path(__file__).resolve().parent.parent
HADOOP_LOGS = REPO_ROOT / "hadoop-logs"
SPARK_LOGS = REPO_ROOT / "spark-logs"
SPARK_CLIENT = os.environ.get("SPARK_CLIENT_CONTAINER", "spark-hadoop-spark-client-1")
NAMENODE_CONTAINER = os.environ.get("NAMENODE_CONTAINER", "spark-hadoop-namenode-1")


def _docker_compose_running() -> bool:
    """Check if docker compose stack is up."""
    try:
        result = subprocess.run(
            ["docker", "compose", "ps", "-a"],
            cwd=REPO_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
            timeout=10,
        )
        if result.returncode != 0:
            return False
        out = result.stdout + result.stderr
        return "namenode" in out.lower() and "spark-client" in out.lower()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return False


@pytest.fixture(scope="session")
def cluster_running():
    """Skip tests if cluster is not running."""
    # #region agent log
    _log_path = Path("/home/rbrooker/repo/spark-hadoop/.cursor/debug-733c0a.log")
    try:
        _files = [(p.name, p.stat().st_size) for p in HADOOP_LOGS.iterdir() if p.is_file()] if HADOOP_LOGS.exists() else []
        with open(_log_path, "a", encoding="utf-8") as _lf:
            _lf.write(
                '{"sessionId":"733c0a","hypothesisId":"B","location":"conftest:cluster_running","message":"session start","data":{"REPO_ROOT":' + json.dumps(str(REPO_ROOT)) + ',"HADOOP_LOGS":' + json.dumps(str(HADOOP_LOGS)) + ',"hadoop_logs_files":' + json.dumps(_files) + '},"timestamp":' + str(int(time.time() * 1000)) + "}\n"
            )
    except OSError:
        pass
    # #endregion
    if not _docker_compose_running():
        pytest.skip("Docker compose stack not running. Start with: docker compose up -d")
    return True


@pytest.fixture
def hadoop_logs(cluster_running):
    """Path to hadoop logs directory."""
    return HADOOP_LOGS


@pytest.fixture
def spark_logs(cluster_running):
    """Path to spark logs directory."""
    return SPARK_LOGS


def read_log_tail(path: Path, lines: int = 500) -> str:
    """Read last N lines of a log file."""
    # #region agent log
    _log_path = Path("/home/rbrooker/repo/spark-hadoop/.cursor/debug-733c0a.log")
    try:
        with open(_log_path, "a", encoding="utf-8") as _lf:
            _lf.write(
                '{"sessionId":"733c0a","hypothesisId":"B","location":"conftest:read_log_tail","message":"read_log_tail called","data":{"path":str(path),"exists":path.exists(),"size":path.stat().st_size if path.exists() else 0},"timestamp":' + str(int(time.time() * 1000)) + "}\n"
            )
    except OSError:
        pass
    # #endregion
    if not path.exists():
        return ""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            content = f.read()
        all_lines = content.strip().split("\n")
        return "\n".join(all_lines[-lines:])
    except OSError:
        return ""
