package podman

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/stephane-klein/sklein-devbox/pkg/ssh"
)

// ContainerStatus holds information about a container
type ContainerStatus struct {
	ID        string
	Name      string
	Running   bool
	SSHPort   string
	StartedAt time.Time
	ExitCode  int
}

// FindContainer searches for a container by instance name
// Returns container ID, running status, and error
func FindContainer(instanceName string) (string, bool, error) {
	// List containers with the label
	cmd := exec.Command("podman", "ps", "-a",
		"--filter", fmt.Sprintf("label=sklein-devbox-name=%s", instanceName),
		"--format", "{{.ID}}|{{.State}}",
	)

	output, err := cmd.Output()
	if err != nil {
		return "", false, nil // Container not found
	}

	lines := strings.TrimSpace(string(output))
	if lines == "" {
		return "", false, nil
	}

	parts := strings.Split(lines, "|")
	if len(parts) < 2 {
		return "", false, nil
	}

	containerID := parts[0]
	state := parts[1]
	running := state == "running"

	return containerID, running, nil
}

// GetContainerSSHPort retrieves the mapped SSH port (2222) for a container
func GetContainerSSHPort(containerID string) (string, error) {
	cmd := exec.Command("podman", "port", containerID, "2222")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get SSH port: %w", err)
	}

	// Output format: "0.0.0.0:49234" or just port number
	portMapping := strings.TrimSpace(string(output))
	if portMapping == "" {
		return "", fmt.Errorf("no port mapping found for port 2222")
	}

	// Extract port from "0.0.0.0:49234"
	parts := strings.Split(portMapping, ":")
	if len(parts) == 2 {
		return parts[1], nil
	}

	return portMapping, nil
}

// buildContainerArgs builds the podman run arguments
func buildContainerArgs(homeDir, workspaceDir, instanceName string, secrets *SecretOptions) ([]string, error) {
	// Ensure SSH keys exist and get public key path
	_, publicKeyPath, err := ssh.GetKeyPaths()
	if err != nil {
		return nil, fmt.Errorf("failed to get SSH key paths: %w", err)
	}

	// Get host home directory for other mounts
	hostHome, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	// Build container name
	containerName := fmt.Sprintf("sklein-devbox-%s", instanceName)

	// Get SSH host keys directory
	sshHostKeysDir, _ := ssh.GetSSHHostKeysDir()

	args := []string{
		"run", "-d",
		"--name", containerName,
		"--label=app=sklein-devbox",
		"--label", fmt.Sprintf("sklein-devbox-name=%s", instanceName),
		"--userns=keep-id",
		"--cap-add=SETUID",
		"--cap-add=SETGID",
		"-e", "TERM",
		"-e", fmt.Sprintf("SKLEIN_DEVBOX_NAME=%s", instanceName),
		"-v", workspaceDir + ":/workspace:U",
		"-v", homeDir + ":/home/sklein:U",
		"-v", publicKeyPath + ":/tmp/devbox-ssh-key.pub:ro",
		"-v", sshHostKeysDir + ":/var/lib/sklein-devbox/ssh-host-keys:U",
		"-p", "2222",
	}

	// Add gopass environment variable if enabled
	if secrets.Gopass {
		args = append(args, "-e", "SKLEIN_DEVBOX_GOPASS=1")
	}

	// Add secret-related mounts with validation
	if secrets.SshKeyFile != "" {
		if _, err := os.Stat(secrets.SshKeyFile); err != nil {
			return nil, fmt.Errorf("SSH key file not found: %s", secrets.SshKeyFile)
		}
		args = append(args, "-v", secrets.SshKeyFile+":/tmp/sklein-devbox-ssh-key:ro")
	}

	if secrets.AgeKeyFile != "" {
		if _, err := os.Stat(secrets.AgeKeyFile); err != nil {
			return nil, fmt.Errorf("Age key file not found: %s", secrets.AgeKeyFile)
		}
		args = append(args, "-v", secrets.AgeKeyFile+":/tmp/sklein-devbox-age-key:ro")
	}

	// Mount host SSH directory if it exists and not disabled
	if !secrets.NoSshMount {
		sshDir := filepath.Join(hostHome, ".ssh")
		if _, err := os.Stat(sshDir); err == nil {
			args = append(args, "-v", sshDir+":/home/sklein/.host-ssh:ro")
		}
	}

	// Mount gopass directories if they exist and not disabled
	if !secrets.NoGopassMount {
		gopassConfigDir := filepath.Join(hostHome, ".config", "gopass")
		gopassDataDir := filepath.Join(hostHome, ".local", "share", "gopass")

		hasGopassConfig := false
		hasGopassData := false

		if _, err := os.Stat(gopassConfigDir); err == nil {
			hasGopassConfig = true
		}
		if _, err := os.Stat(gopassDataDir); err == nil {
			hasGopassData = true
		}

		if hasGopassConfig || hasGopassData {
			// Mount gopass age identities if directory exists
			ageIdentitiesDir := filepath.Join(hostHome, ".config", "gopass", "age", "identities")
			if _, err := os.Stat(ageIdentitiesDir); err == nil {
				args = append(args, "-v", ageIdentitiesDir+":/home/sklein/.config/gopass/age/identities:U")
			}

			// Mount gopass data directory if it exists
			if hasGopassData {
				args = append(args, "-v", gopassDataDir+":/home/sklein/.local/share/gopass:U")
			}
		}
	}

	// Add image at the end (ENTRYPOINT ["/init"] is already defined in the image)
	args = append(args, "ghcr.io/stephane-klein/sklein-devbox:latest")

	return args, nil
}

// DryRunStartContainer returns the podman run command formatted for dry-run output
func DryRunStartContainer(homeDir, workspaceDir, instanceName string, secrets *SecretOptions) (string, error) {
	args, err := buildContainerArgs(homeDir, workspaceDir, instanceName, secrets)
	if err != nil {
		return "", err
	}

	var cmd strings.Builder
	cmd.WriteString("podman ")

	// Flags that take a value should be grouped with their value
	flagsWithValues := map[string]bool{
		"--name":  true,
		"--label": true,
		"-e":      true,
		"-v":      true,
		"-p":      true,
	}

	for i := 0; i < len(args); i++ {
		arg := args[i]

		if i == 0 {
			// First argument (e.g., "run")
			cmd.WriteString(arg)
		} else if flagsWithValues[arg] && i+1 < len(args) {
			// This is a flag with a value, group them
			cmd.WriteString(" \\\n  " + arg + " " + args[i+1])
			i++ // Skip the value in next iteration
		} else if strings.HasPrefix(arg, "--") && strings.Contains(arg, "=") {
			// Flag with inline value like --label=app=sklein-devbox
			cmd.WriteString(" \\\n  " + arg)
		} else {
			// Regular argument
			cmd.WriteString(" \\\n  " + arg)
		}
	}

	return cmd.String(), nil
}

// StartContainer starts a new container in detached mode
// Returns container ID, SSH port, and error
func StartContainer(homeDir, workspaceDir, instanceName string, secrets *SecretOptions) (string, string, error) {
	// Ensure SSH host keys directory exists
	sshHostKeysDir, err := ssh.GetSSHHostKeysDir()
	if err != nil {
		return "", "", fmt.Errorf("failed to get SSH host keys directory: %w", err)
	}
	if err := os.MkdirAll(sshHostKeysDir, 0700); err != nil {
		return "", "", fmt.Errorf("failed to create SSH host keys directory: %w", err)
	}

	args, err := buildContainerArgs(homeDir, workspaceDir, instanceName, secrets)
	if err != nil {
		return "", "", err
	}

	// Execute podman run
	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return "", "", err
	}

	cmd := exec.Command(podmanPath, args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "", "", fmt.Errorf("failed to start container: %w\nPodman output:\n%s", err, string(output))
	}

	containerID := strings.TrimSpace(string(output))

	// Get the mapped SSH port
	sshPort, err := GetContainerSSHPort(containerID)
	if err != nil {
		// Clean up container if we can't get the port
		StopContainer(containerID)
		return "", "", err
	}

	return containerID, sshPort, nil
}

// DryRunStopContainer returns the stop and rm commands formatted for dry-run output
func DryRunStopContainer(instanceName string) string {
	containerName := fmt.Sprintf("sklein-devbox-%s", instanceName)
	return fmt.Sprintf("podman stop -t 30 %s && \\\npodman rm %s", containerName, containerName)
}

// StopContainer stops and removes a container
func StopContainer(containerID string) error {
	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return err
	}

	// Stop the container
	stopCmd := exec.Command(podmanPath, "stop", "-t", "30", containerID)
	stopCmd.Run() // Ignore error, container might already be stopped

	// Remove the container
	rmCmd := exec.Command(podmanPath, "rm", containerID)
	return rmCmd.Run()
}

// GetContainerStatus retrieves detailed status information about a container
func GetContainerStatus(instanceName string) (*ContainerStatus, error) {
	containerID, running, err := FindContainer(instanceName)
	if err != nil {
		return nil, err
	}

	if containerID == "" {
		return nil, nil // Container not found
	}

	status := &ContainerStatus{
		ID:      containerID,
		Name:    fmt.Sprintf("sklein-devbox-%s", instanceName),
		Running: running,
	}

	if running {
		sshPort, err := GetContainerSSHPort(containerID)
		if err == nil {
			status.SSHPort = sshPort
		}
	}

	// Get additional info via inspect
	podmanPath, _ := GetPodmanBinPath()
	inspectCmd := exec.Command(podmanPath, "inspect", containerID)
	output, err := inspectCmd.Output()
	if err == nil {
		var inspectData []map[string]interface{}
		if json.Unmarshal(output, &inspectData) == nil && len(inspectData) > 0 {
			data := inspectData[0]
			if state, ok := data["State"].(map[string]interface{}); ok {
				if startedAt, ok := state["StartedAt"].(string); ok && startedAt != "" {
					status.StartedAt, _ = time.Parse(time.RFC3339Nano, startedAt)
				}
				if exitCode, ok := state["ExitCode"].(float64); ok {
					status.ExitCode = int(exitCode)
				}
			}
		}
	}

	return status, nil
}

// GetAllContainers lists all sklein-devbox containers
func GetAllContainers() ([]ContainerStatus, error) {
	cmd := exec.Command("podman", "ps", "-a",
		"--filter", "label=app=sklein-devbox",
		"--format", "{{.ID}}|{{.Names}}|{{.State}}|{{.Labels}}",
	)

	output, err := cmd.Output()
	if err != nil {
		return nil, nil
	}

	var containers []ContainerStatus
	lines := strings.Split(string(output), "\n")

	for _, line := range lines {
		if line == "" {
			continue
		}

		parts := strings.Split(line, "|")
		if len(parts) < 3 {
			continue
		}

		container := ContainerStatus{
			ID:      parts[0],
			Name:    parts[1],
			Running: parts[2] == "running",
		}

		// Parse labels to get instance name
		if len(parts) > 3 {
			labels := parts[3]
			if strings.Contains(labels, "sklein-devbox-name=") {
				// Extract instance name from labels
				for _, label := range strings.Split(labels, ",") {
					if strings.HasPrefix(label, "sklein-devbox-name=") {
						instanceName := strings.TrimPrefix(label, "sklein-devbox-name=")
						// Get SSH port if running
						if container.Running {
							port, _ := GetContainerSSHPort(container.ID)
							container.SSHPort = port
						}
						_ = instanceName
						break
					}
				}
			}
		}

		containers = append(containers, container)
	}

	return containers, nil
}
