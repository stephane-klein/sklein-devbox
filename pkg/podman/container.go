package podman

import (
	"encoding/json"
	"fmt"
	"hash/fnv"
	"net"
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
	HomeName  string
	Workspace string
	Running   bool
	SSHPort   string
	StartedAt time.Time
	ExitCode  int
}

// podmanPsEntry represents the JSON output of `podman ps --format json`
type podmanPsEntry struct {
	Id     string            `json:"Id"`
	Names  []string          `json:"Names"`
	State  string            `json:"State"`
	Labels map[string]string `json:"Labels"`
	Ports  []struct {
		HostPort int `json:"host_port"`
	} `json:"Ports"`
}

// GenerateContainerName generates a unique container name based on home name and workspace path.
// It uses a 32-bit FNV-1a hash of the absolute workspace path, truncated to 8 hexadecimal characters.
func GenerateContainerName(homeName, workspacePath string) string {
	absPath, err := filepath.Abs(workspacePath)
	if err != nil {
		absPath = workspacePath
	}

	h := fnv.New32a()
	h.Write([]byte(absPath))
	hash := h.Sum32()

	return fmt.Sprintf("sklein-devbox-%s-%08x", homeName, hash)
}

// FindContainer searches for a container by instance name and workspace path.
// It targets the exact container via its generated name.
// Returns container ID, running status, and error.
func FindContainer(instanceName, workspacePath string) (string, bool, error) {
	containerName := GenerateContainerName(instanceName, workspacePath)

	cmd := exec.Command("podman", "ps", "-a",
		"--filter", fmt.Sprintf("name=%s", containerName),
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

// FindAllContainersForHomeName finds all containers associated with a given home name,
// regardless of workspace.
func FindAllContainersForHomeName(instanceName string) ([]ContainerStatus, error) {
	cmd := exec.Command("podman", "ps", "-a",
		"--filter", fmt.Sprintf("label=sklein-devbox-name=%s", instanceName),
		"--format", "json",
	)

	output, err := cmd.Output()
	if err != nil {
		return nil, nil
	}

	var entries []podmanPsEntry
	if err := json.Unmarshal(output, &entries); err != nil {
		return nil, nil
	}

	var containers []ContainerStatus
	for _, e := range entries {
		container := ContainerStatus{
			ID:        e.Id,
			HomeName:  e.Labels["sklein-devbox-name"],
			Workspace: e.Labels["sklein-devbox-workspace"],
			Running:   e.State == "running",
		}

		if len(e.Names) > 0 {
			container.Name = e.Names[0]
		}

		if port, ok := e.Labels["sklein-devbox-ssh-port"]; ok && port != "" {
			container.SSHPort = port
		}

		containers = append(containers, container)
	}

	return containers, nil
}

// GetContainerSSHPort retrieves the SSH port for a container from its label.
func GetContainerSSHPort(containerID string) (string, error) {
	cmd := exec.Command("podman", "inspect", "--format", "{{index .Config.Labels \"sklein-devbox-ssh-port\"}}", containerID)
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get SSH port label: %w", err)
	}

	port := strings.TrimSpace(string(output))
	if port == "" {
		return "", fmt.Errorf("container uses an obsolete configuration without an SSH port label, please stop and restart it")
	}

	return port, nil
}

// FindNextFreePort finds the next available TCP port starting from start.
// It tries up to maxAttempts ports.
func FindNextFreePort(start, maxAttempts int) (int, error) {
	for port := start; port < start+maxAttempts; port++ {
		addr := fmt.Sprintf(":%d", port)
		ln, err := net.Listen("tcp", addr)
		if err == nil {
			ln.Close()
			return port, nil
		}
	}
	return 0, fmt.Errorf("no free port found in range %d-%d", start, start+maxAttempts-1)
}

// buildContainerArgs builds the podman run arguments.
// It returns the allocated SSH port, the arguments slice, and any error.
func buildContainerArgs(homeDir, workspaceDir, instanceName string, opts *ContainerOptions) (string, []string, error) {
	// Find next free SSH port starting at 2222
	sshPortNum, err := FindNextFreePort(2222, 1000)
	if err != nil {
		return "", nil, fmt.Errorf("failed to find free SSH port: %w", err)
	}
	sshPort := fmt.Sprintf("%d", sshPortNum)

	// Ensure SSH keys exist and get public key path
	_, publicKeyPath, err := ssh.GetKeyPaths()
	if err != nil {
		return "", nil, fmt.Errorf("failed to get SSH key paths: %w", err)
	}

	// Get host home directory for other mounts
	hostHome, err := os.UserHomeDir()
	if err != nil {
		return "", nil, fmt.Errorf("failed to get home directory: %w", err)
	}

	// Ensure workspace path is absolute for consistent naming and labeling
	absWorkspace, err := filepath.Abs(workspaceDir)
	if err != nil {
		absWorkspace = workspaceDir
	}

	// Build container name
	containerName := GenerateContainerName(instanceName, absWorkspace)

	// Get SSH host keys directory
	sshHostKeysDir, _ := ssh.GetSSHHostKeysDir()

	args := []string{
		"run", "-d", "--replace",
		"--name", containerName,
		"--label=app=sklein-devbox",
		"--label", fmt.Sprintf("sklein-devbox-name=%s", instanceName),
		"--label", fmt.Sprintf("sklein-devbox-workspace=%s", absWorkspace),
		"--label", fmt.Sprintf("sklein-devbox-ssh-port=%s", sshPort),
		"--userns=keep-id",
		"--cap-add=SETUID",
		"--cap-add=SETGID",
		"-e", "TERM",
		"-e", fmt.Sprintf("SKLEIN_DEVBOX_NAME=%s", instanceName),
		"-e", fmt.Sprintf("SKLEIN_DEVBOX_SSH_PORT=%s", sshPort),
		"-v", workspaceDir + ":/workspace:U",
		"-v", homeDir + ":/home/sklein:U",
		"-v", publicKeyPath + ":/tmp/devbox-ssh-key.pub:ro",
		"-v", sshHostKeysDir + ":/var/lib/sklein-devbox/ssh-host-keys:U",
	}

	if opts.NetworkHost {
		args = append(args, "--network=host")
	} else {
		args = append(args, "-p", fmt.Sprintf("%s:%s", sshPort, sshPort))
	}

	// Add gopass environment variable if enabled
	if opts.Gopass {
		args = append(args, "-e", "SKLEIN_DEVBOX_GOPASS=1")
	}

	// Add secret-related mounts with validation
	if opts.SshKeyFile != "" {
		if _, err := os.Stat(opts.SshKeyFile); err != nil {
			return "", nil, fmt.Errorf("SSH key file not found: %s", opts.SshKeyFile)
		}
		args = append(args, "-v", opts.SshKeyFile+":/tmp/sklein-devbox-ssh-key:ro")
	}

	if opts.AgeKeyFile != "" {
		if _, err := os.Stat(opts.AgeKeyFile); err != nil {
			return "", nil, fmt.Errorf("Age key file not found: %s", opts.AgeKeyFile)
		}
		args = append(args, "-v", opts.AgeKeyFile+":/tmp/sklein-devbox-age-key:ro")
	}

	// Mount host SSH directory if it exists and not disabled
	if !opts.NoSshMount {
		sshDir := filepath.Join(hostHome, ".ssh")
		if _, err := os.Stat(sshDir); err == nil {
			args = append(args, "-v", sshDir+":/home/sklein/.host-ssh:ro")
		}
	}

	// Mount gopass directories if they exist and not disabled
	if !opts.NoGopassMount {
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

	// Mount mise cache directory if not disabled
	if !opts.NoMiseCacheMount {
		miseCacheDir := opts.MiseCacheDir
		if miseCacheDir == "" {
			miseCacheDir = filepath.Join(hostHome, ".local", "share", "mise", "installs")
		}
		os.MkdirAll(miseCacheDir, 0755)
		args = append(args, "-v", miseCacheDir+":/home/sklein/.local/share/mise/installs/:U")
	}

	// Mount DBus socket if available on host (for D-Bus communication with host)
	runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
	if runtimeDir == "" {
		runtimeDir = filepath.Join("/run", "user", fmt.Sprintf("%d", os.Getuid()))
	}
	dbusSocketPath := filepath.Join(runtimeDir, "bus")
	if _, err := os.Stat(dbusSocketPath); err == nil {
		args = append(args, "-v", dbusSocketPath+":/tmp/dbus-remote.sock")
	}

	// Mount PulseAudio socket if available on host and not disabled
	if !opts.NoPulseAudio {
		pulseSocketPath := filepath.Join(runtimeDir, "pulse", "native")
		if _, err := os.Stat(pulseSocketPath); err == nil {
			args = append(args, "-v", pulseSocketPath+":/tmp/pulse-remote.sock")
		}
	}

	if opts.PodmanSocket {
		hostSocketPath := filepath.Join(runtimeDir, "podman", "podman.sock")
		args = append(args, "-v", hostSocketPath+":/run/user/1000/podman/podman.sock")
		args = append(args, "-e", "XDG_RUNTIME_DIR=/run/user/1000")
		args = append(args, "-e", "CONTAINER_HOST=unix:///run/user/1000/podman/podman.sock")
	}

	// Add image at the end (ENTRYPOINT ["/init"] is already defined in the image)
	args = append(args, "ghcr.io/stephane-klein/sklein-devbox:latest")

	return sshPort, args, nil
}

// DryRunStartContainer returns the podman run command formatted for dry-run output
func DryRunStartContainer(homeDir, workspaceDir, instanceName string, opts *ContainerOptions) (string, error) {
	_, args, err := buildContainerArgs(homeDir, workspaceDir, instanceName, opts)
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

// PullImage pulls the latest sklein-devbox container image
func PullImage() error {
	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return err
	}

	cmd := exec.Command(podmanPath, "pull", "--quiet", "ghcr.io/stephane-klein/sklein-devbox:latest")
	_, err = cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("podman pull failed: %w", err)
	}

	return nil
}

// StartContainer starts a new container in detached mode
// Returns container ID, SSH port, and error
func StartContainer(homeDir, workspaceDir, instanceName string, opts *ContainerOptions) (string, string, error) {
	// Ensure SSH host keys directory exists
	sshHostKeysDir, err := ssh.GetSSHHostKeysDir()
	if err != nil {
		return "", "", fmt.Errorf("failed to get SSH host keys directory: %w", err)
	}
	if err := os.MkdirAll(sshHostKeysDir, 0700); err != nil {
		return "", "", fmt.Errorf("failed to create SSH host keys directory: %w", err)
	}

	// Ensure mise parent directory exists in instance home so Podman
	// chowns it correctly via the :U flag on the home mount
	miseParentDir := filepath.Join(homeDir, ".local", "share", "mise")
	if err := os.MkdirAll(miseParentDir, 0755); err != nil {
		return "", "", fmt.Errorf("failed to create mise parent directory: %w", err)
	}

	if opts.PodmanSocket {
		if err := EnsurePodmanSocket(); err != nil {
			return "", "", err
		}
	}

	sshPort, args, err := buildContainerArgs(homeDir, workspaceDir, instanceName, opts)
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

	return containerID, sshPort, nil
}

// DryRunStopContainer returns the stop and rm commands formatted for dry-run output
func DryRunStopContainer(instanceName, workspacePath string) string {
	containerName := GenerateContainerName(instanceName, workspacePath)
	return fmt.Sprintf("podman stop -t 30 %s && \\npodman rm %s", containerName, containerName)
}

// WaitContainerStopped polls until the container is no longer running.
// It checks via podman inspect every 2 seconds, up to maxAttempts times.
func WaitContainerStopped(containerID string, maxAttempts int) error {
	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return err
	}

	for i := 0; i < maxAttempts; i++ {
		cmd := exec.Command(podmanPath, "inspect", "--format", "{{.State.Status}}", containerID)
		output, err := cmd.Output()
		if err != nil {
			return nil
		}
		status := strings.TrimSpace(string(output))
		if status != "running" {
			return nil
		}
		time.Sleep(2 * time.Second)
	}

	return fmt.Errorf("container %s is still running after %d attempts", containerID[:12], maxAttempts)
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
func GetContainerStatus(instanceName, workspacePath string) (*ContainerStatus, error) {
	containerID, running, err := FindContainer(instanceName, workspacePath)
	if err != nil {
		return nil, err
	}

	if containerID == "" {
		return nil, nil // Container not found
	}

	status := &ContainerStatus{
		ID:        containerID,
		Name:      GenerateContainerName(instanceName, workspacePath),
		HomeName:  instanceName,
		Workspace: workspacePath,
		Running:   running,
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
		"--format", "json",
	)

	output, err := cmd.Output()
	if err != nil {
		return nil, nil
	}

	var entries []podmanPsEntry
	if err := json.Unmarshal(output, &entries); err != nil {
		return nil, nil
	}

	var containers []ContainerStatus
	for _, e := range entries {
		container := ContainerStatus{
			ID:        e.Id,
			HomeName:  e.Labels["sklein-devbox-name"],
			Workspace: e.Labels["sklein-devbox-workspace"],
			Running:   e.State == "running",
		}

		if len(e.Names) > 0 {
			container.Name = e.Names[0]
		}

		if port, ok := e.Labels["sklein-devbox-ssh-port"]; ok && port != "" {
			container.SSHPort = port
		}

		containers = append(containers, container)
	}

	return containers, nil
}
