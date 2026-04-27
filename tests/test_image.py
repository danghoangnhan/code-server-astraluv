"""Test basic image functionality and Kubeflow compliance"""

import os
import subprocess

import pytest

IMAGE_NAME = (
    os.getenv("HARBOR_REGISTRY", "harbor.thinktron.co")
    + "/"
    + os.getenv("HARBOR_PROJECT", "sec1")
    + "/code-server-astral-uv:latest"
)

# Configuration
CONTAINER_COMMAND_TIMEOUT = 120
DEFAULT_PYTHON_VERSION = "3.11"

# When RUN_IN_HOST=true, run commands directly in the current process instead of via
# `docker run`. Set this in CI when the GitLab job container *is* the image under test
# (Kaniko/k3s runner has no Docker daemon to spawn nested containers).
RUN_IN_HOST = os.getenv("RUN_IN_HOST", "").lower() in ("1", "true", "yes")


def run_in_container(command, timeout=CONTAINER_COMMAND_TIMEOUT):
    """Execute command in image — directly when RUN_IN_HOST=true (CI), otherwise via `docker run`."""
    if RUN_IN_HOST:
        cmd = ["bash", "-c", command]
    else:
        cmd = ["docker", "run", "--rm", IMAGE_NAME, "bash", "-c", command]
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result
    except subprocess.TimeoutExpired as e:
        # Create a result-like object for timeout errors
        class TimeoutResult:
            returncode = 1
            stdout = ""
            stderr = f"Command timed out after {timeout} seconds"

        return TimeoutResult()


# =============================================================================
# UV Tests
# =============================================================================


def test_uv_installed():
    """Test Astral UV is installed"""
    result = run_in_container("uv --version")
    assert result.returncode == 0, f"uv command failed: {result.stderr}"
    assert "uv" in result.stdout.lower(), f"uv not in output: {result.stdout}"
    print(f"✓ UV version: {result.stdout.strip()}")


def test_uvx_installed():
    """Test uvx is installed"""
    result = run_in_container("uvx --version")
    assert result.returncode == 0, f"uvx command failed: {result.stderr}"
    print(f"✓ uvx version: {result.stdout.strip()}")


def test_uv_python_installed():
    """Test Python is installed via UV"""
    result = run_in_container("uv python list")
    assert result.returncode == 0, f"uv python list failed: {result.stderr}"
    assert "3.11" in result.stdout or "cpython" in result.stdout.lower(), (
        f"Python not found in output: {result.stdout}"
    )
    print(f"✓ UV Python installed:\n{result.stdout.strip()}")


def test_uv_can_install_python_version():
    """Test UV can install additional Python versions"""
    result = run_in_container("uv python install 3.10 && uv python list | grep 3.10")
    assert result.returncode == 0, f"Failed to install Python 3.10: {result.stderr}"
    assert "3.10" in result.stdout, (
        f"Python 3.10 not found after installation: {result.stdout}"
    )
    print("✓ UV can install Python 3.10")


def test_uv_pip_install():
    """Test UV pip can install packages (into a venv — image has no system Python)"""
    cmd = (
        f"uv python install {DEFAULT_PYTHON_VERSION} >/dev/null 2>&1 && "
        f"uv venv /tmp/uv-pip-test --python {DEFAULT_PYTHON_VERSION} && "
        "uv pip install --python /tmp/uv-pip-test/bin/python requests && "
        "/tmp/uv-pip-test/bin/python -c 'import requests; print(requests.__version__)'"
    )
    result = run_in_container(cmd)
    assert result.returncode == 0, f"Failed to install requests: {result.stderr}"
    version_output = result.stdout.strip().splitlines()[-1]
    assert version_output, "No version output from requests"
    print(f"✓ UV pip install works: requests {version_output}")


def test_uv_venv_create():
    """Test UV can create virtual environments"""
    result = run_in_container("uv venv /tmp/testenv && ls /tmp/testenv/bin/python")
    assert result.returncode == 0, f"Failed to create venv: {result.stderr}"
    print("✓ UV venv creation works")


# =============================================================================
# SSH Tests
# =============================================================================


def test_sshd_installed():
    """Test sshd is installed"""
    result = run_in_container("test -f /usr/sbin/sshd && echo 'yes' || echo 'no'")
    assert result.returncode == 0, f"test command failed: {result.stderr}"
    assert "yes" in result.stdout, f"sshd not found: {result.stdout}"
    print("✓ sshd is installed")


def test_ssh_config_secure():
    """Test SSH config has secure defaults"""
    result = run_in_container("cat /etc/ssh/sshd_config")
    assert result.returncode == 0, f"Failed to read sshd_config: {result.stderr}"
    config = result.stdout
    assert "PasswordAuthentication no" in config, "PasswordAuthentication should be disabled"
    assert "PermitRootLogin no" in config, "Root login should be disabled"
    assert "PubkeyAuthentication yes" in config, "Pubkey auth should be enabled"
    assert "AllowUsers jovyan" in config, "Only jovyan should be allowed"
    print("✓ SSH config is secure (pubkey-only, no root, no password)")


# =============================================================================
# Kubeflow Compliance Tests
# =============================================================================


def test_user_is_jovyan():
    """Test running as jovyan user (Kubeflow requirement)"""
    result = run_in_container("whoami")
    assert result.returncode == 0, f"whoami command failed: {result.stderr}"
    assert "jovyan" in result.stdout, f"User is not jovyan: {result.stdout}"
    print(f"✓ User is jovyan")


def test_user_id():
    """Test user has UID 1000 (Kubeflow requirement)"""
    result = run_in_container("id -u")
    assert result.returncode == 0, f"id command failed: {result.stderr}"
    uid = result.stdout.strip()
    assert uid == "1000", f"UID is {uid}, expected 1000"
    print(f"✓ UID is 1000")


def test_user_gid():
    """Test user has GID 100 (Kubeflow requirement)"""
    result = run_in_container("id -g")
    assert result.returncode == 0, f"id command failed: {result.stderr}"
    gid = result.stdout.strip()
    assert gid == "100", f"GID is {gid}, expected 100"
    print("✓ GID is 100")


def test_home_directory():
    """Test home directory is /home/jovyan (Kubeflow requirement)"""
    result = run_in_container("echo $HOME")
    assert result.returncode == 0, f"echo command failed: {result.stderr}"
    home = result.stdout.strip()
    assert home == "/home/jovyan", f"HOME is {home}, expected /home/jovyan"
    print(f"✓ HOME is /home/jovyan")


def test_s6_overlay_installed():
    """Test s6-overlay is installed"""
    result = run_in_container("test -f /init && echo 'yes' || echo 'no'")
    assert result.returncode == 0, f"test command failed: {result.stderr}"
    assert "yes" in result.stdout, f"s6-overlay not found: {result.stdout}"
    print(f"✓ s6-overlay is installed")


def test_project_directory():
    """Test project directory exists"""
    result = run_in_container("test -d /home/jovyan/project && echo 'yes' || echo 'no'")
    assert result.returncode == 0, f"test command failed: {result.stderr}"
    assert "yes" in result.stdout, f"project directory not found: {result.stdout}"
    print("✓ Project directory exists")


def test_home_writable():
    """Test home directory is writable"""
    result = run_in_container(
        "touch /home/jovyan/test-file && rm /home/jovyan/test-file && echo 'success'"
    )
    assert result.returncode == 0, f"write test failed: {result.stderr}"
    assert "success" in result.stdout, f"Unexpected output: {result.stdout}"
    print("✓ Home directory is writable")


# =============================================================================
# System Tools Tests
# =============================================================================


def test_git_installed():
    """Test git is installed"""
    result = run_in_container("git --version")
    assert result.returncode == 0, f"git command failed: {result.stderr}"
    print(f"✓ {result.stdout.strip()}")


def test_curl_installed():
    """Test curl is installed"""
    result = run_in_container("curl --version | head -n 1")
    assert result.returncode == 0, f"curl command failed: {result.stderr}"
    print(f"✓ {result.stdout.strip()}")


def test_cuda_environment():
    """Test CUDA environment variables are set"""
    result = run_in_container("echo $CUDA_HOME")
    assert result.returncode == 0, f"echo command failed: {result.stderr}"
    cuda_home = result.stdout.strip()
    assert cuda_home == "/usr/local/cuda", f"CUDA_HOME is {cuda_home}, expected /usr/local/cuda"
    print(f"✓ CUDA_HOME is set: {cuda_home}")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
