"""
Pytest configuration and fixtures for log verification tests.

Verifies that logging captures the right events per Requirements.md:
- CRUD activities (HDFS audit)
- Program initiations (Spark, YARN)
- UI access (jetty logs)
- Hostname prefix for SIEM correlation
- Metrics output
"""

import os
import subprocess
from pathlib import Path

import pytest

# Paths relative to repo root
REPO_ROOT = Path(__file__).resolve().parent.parent
LOGS_DIR = REPO_ROOT / "logs"
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
    if not _docker_compose_running():
        pytest.skip("Docker compose stack not running. Start with: docker compose up -d")
    return True


@pytest.fixture
def logs_dir(cluster_running):
    """Path to unified logs directory."""
    return LOGS_DIR


def read_log_tail(path: Path, lines: int = 500) -> str:
    """Read last N lines of a log file."""
    if not path.exists():
        return ""
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            content = f.read()
        all_lines = content.strip().split("\n")
        return "\n".join(all_lines[-lines:])
    except OSError:
        return ""
