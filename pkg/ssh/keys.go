package ssh

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

// GetSSHDir returns the directory where SSH keys are stored
// All instances share the same keys: ~/.local/share/sklein-devbox/ssh-client-keys/
func GetSSHDir() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	sshDir := filepath.Join(home, ".local", "share", "sklein-devbox", "ssh-client-keys")
	return sshDir, nil
}

// GetSSHHostKeysDir returns the directory where SSH host keys are stored
// Host keys are shared across all instances: ~/.local/share/sklein-devbox/ssh-host-keys/
func GetSSHHostKeysDir() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get home directory: %w", err)
	}

	hostKeysDir := filepath.Join(home, ".local", "share", "sklein-devbox", "ssh-host-keys")
	return hostKeysDir, nil
}

// GetKeyPaths returns the paths to the private and public SSH keys
func GetKeyPaths() (privateKeyPath, publicKeyPath string, err error) {
	sshDir, err := GetSSHDir()
	if err != nil {
		return "", "", err
	}

	privateKeyPath = filepath.Join(sshDir, "id_ed25519")
	publicKeyPath = filepath.Join(sshDir, "id_ed25519.pub")
	return privateKeyPath, publicKeyPath, nil
}

// EnsureSSHKeys generates SSH Ed25519 keys if they don't exist
func EnsureSSHKeys() error {
	sshDir, err := GetSSHDir()
	if err != nil {
		return err
	}

	// Create SSH directory if it doesn't exist
	if err := os.MkdirAll(sshDir, 0700); err != nil {
		return fmt.Errorf("failed to create SSH directory: %w", err)
	}

	privateKeyPath, publicKeyPath, err := GetKeyPaths()
	if err != nil {
		return err
	}

	// Check if keys already exist
	if _, err := os.Stat(privateKeyPath); err == nil {
		// Keys already exist
		return nil
	}

	// Generate new Ed25519 key pair
	cmd := exec.Command("ssh-keygen",
		"-t", "ed25519",
		"-f", privateKeyPath,
		"-N", "",
		"-q",
	)

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to generate SSH keys: %w", err)
	}

	// Set proper permissions on private key
	if err := os.Chmod(privateKeyPath, 0600); err != nil {
		return fmt.Errorf("failed to set permissions on private key: %w", err)
	}

	// Set proper permissions on public key
	if err := os.Chmod(publicKeyPath, 0644); err != nil {
		return fmt.Errorf("failed to set permissions on public key: %w", err)
	}

	return nil
}

// PublicKeyContent returns the content of the public key file
func PublicKeyContent() (string, error) {
	_, publicKeyPath, err := GetKeyPaths()
	if err != nil {
		return "", err
	}

	content, err := os.ReadFile(publicKeyPath)
	if err != nil {
		return "", fmt.Errorf("failed to read public key: %w", err)
	}

	return string(content), nil
}
