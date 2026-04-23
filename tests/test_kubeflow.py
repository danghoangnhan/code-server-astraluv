"""Test Kubeflow compliance and integration"""

import os
import subprocess
import time

import pytest

IMAGE_NAME = (
    os.getenv("HARBOR_REGISTRY", "harbor.thinktron.co")
    + "/"
    + os.getenv("HARBOR_PROJECT", "sec1")
    + "/code-server-astral-uv:latest"
)

# Configuration
MAX_STARTUP_RETRIES = 30
STARTUP_RETRY_DELAY = 1


@pytest.fixture(scope="module")
def running_container():
    """Start a container for testing"""
    container_name = "test-kubeflow-compliance"

    # Clean up any existing container
    subprocess.run(
        ["docker", "rm", "-f", container_name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )

    # Start container
    result = subprocess.run(
        [
            "docker",
            "run",
            "-d",
            "--name",
            container_name,
            "-p",
            "2222:22",
            IMAGE_NAME,
        ],
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, f"Failed to start container: {result.stderr}"

    # Wait for sshd to start
    startup_complete = False
    for attempt in range(MAX_STARTUP_RETRIES):
        check = subprocess.run(
            ["docker", "exec", container_name, "pgrep", "sshd"],
            capture_output=True,
            text=True,
        )
        if check.returncode == 0:
            startup_complete = True
            break

        if attempt < MAX_STARTUP_RETRIES - 1:
            time.sleep(STARTUP_RETRY_DELAY)

    if not startup_complete:
        logs = subprocess.run(
            ["docker", "logs", container_name],
            capture_output=True,
            text=True,
        )
        subprocess.run(["docker", "rm", "-f", container_name], capture_output=True)
        pytest.fail(
            f"Container failed to start after {MAX_STARTUP_RETRIES} retries.\n"
            f"Logs:\n{logs.stdout}\nStderr:\n{logs.stderr}"
        )

    yield container_name

    # Cleanup
    subprocess.run(["docker", "rm", "-f", container_name], capture_output=True)


def test_sshd_process_running(running_container):
    """Test sshd process is running"""
    result = subprocess.run(
        ["docker", "exec", running_container, "pgrep", "sshd"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert result.stdout.strip()
    print(f"✓ sshd process is running (PID: {result.stdout.strip()})")


def test_port_22_exposed(running_container):
    """Test that port 22 is exposed"""
    result = subprocess.run(
        ["docker", "port", running_container, "22"], capture_output=True, text=True
    )
    assert result.returncode == 0
    assert "22" in result.stdout
    print(f"✓ Port 22 is exposed: {result.stdout.strip()}")


def test_jovyan_user(running_container):
    """Test container runs as jovyan user"""
    result = subprocess.run(
        ["docker", "exec", running_container, "whoami"], capture_output=True, text=True
    )
    assert result.returncode == 0
    assert "jovyan" in result.stdout
    print(f"✓ Running as user: {result.stdout.strip()}")


def test_home_directory_writable(running_container):
    """Test /home/jovyan is writable (important for PVC mounts)"""
    result = subprocess.run(
        [
            "docker",
            "exec",
            running_container,
            "bash",
            "-c",
            "touch /home/jovyan/test-file && rm /home/jovyan/test-file && echo 'success'",
        ],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert "success" in result.stdout
    print("✓ /home/jovyan is writable")


def test_project_directory_exists(running_container):
    """Test /home/jovyan/project directory exists"""
    result = subprocess.run(
        ["docker", "exec", running_container, "test", "-d", "/home/jovyan/project"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    print("✓ /home/jovyan/project exists")


def test_s6_overlay_running(running_container):
    """Test s6-overlay is managing processes"""
    result = subprocess.run(
        ["docker", "exec", running_container, "ps", "aux"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert "s6-" in result.stdout or "/init" in result.stdout
    print("✓ s6-overlay is running")


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
