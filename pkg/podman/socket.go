package podman

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

// getPodmanSocketPath returns the host's podman socket path based on the current user's UID.
func getPodmanSocketPath() string {
	uid := os.Getuid()
	return filepath.Join("/run", "user", fmt.Sprintf("%d", uid), "podman", "podman.sock")
}

// EnsurePodmanSocket checks if the podman socket exists and attempts to start it via
// systemd if not. It retries up to 3 times with 200ms intervals.
// If the socket still cannot be found, it returns a hard error.
func EnsurePodmanSocket() error {
	socketPath := getPodmanSocketPath()

	// Check if socket already exists
	if _, err := os.Stat(socketPath); err == nil {
		return nil
	}

	// Attempt to start podman socket via systemd
	cmd := exec.Command("systemctl", "--user", "start", "podman.socket")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf(
			"podman socket not found at %s and failed to start it via systemctl: %w. "+
				"Run 'systemctl --user start podman.socket' manually or use --no-podman-socket to skip this feature",
			socketPath, err,
		)
	}

	// Wait for socket to appear (3 retries, 200ms apart)
	for i := 0; i < 3; i++ {
		time.Sleep(200 * time.Millisecond)
		if _, err := os.Stat(socketPath); err == nil {
			return nil
		}
	}

	return fmt.Errorf(
		"podman socket did not appear at %s after starting podman.socket. "+
			"Run 'systemctl --user start podman.socket' manually or use --no-podman-socket to skip this feature",
		socketPath,
	)
}
