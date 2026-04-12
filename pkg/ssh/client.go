package ssh

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
	"syscall"
)

// ConnectOptions configures an SSH connection
type ConnectOptions struct {
	Port           string
	PrivateKeyPath string
	User           string
	Command        []string
}

// Connect establishes an SSH connection using syscall.Exec
// This replaces the current process with the SSH client
func Connect(opts ConnectOptions) error {
	if opts.User == "" {
		opts.User = "sklein"
	}

	sshArgs := []string{
		"ssh",
		"-t",
		"-i", opts.PrivateKeyPath,
		"-o", "StrictHostKeyChecking=accept-new",
		"-o", "UserKnownHostsFile=/dev/null",
		"-o", "LogLevel=ERROR",
		"-p", opts.Port,
		fmt.Sprintf("%s@localhost", opts.User),
	}

	if len(opts.Command) > 0 {
		sshArgs = append(sshArgs, opts.Command...)
	}

	// Find ssh binary
	sshPath, err := exec.LookPath("ssh")
	if err != nil {
		return fmt.Errorf("ssh not found in PATH: %w", err)
	}

	// Execute ssh (replaces current process)
	env := os.Environ()
	return syscall.Exec(sshPath, sshArgs, env)
}

// ConnectCommand returns an exec.Cmd for SSH connection (for async execution)
func ConnectCommand(opts ConnectOptions) (*exec.Cmd, error) {
	if opts.User == "" {
		opts.User = "sklein"
	}

	sshArgs := []string{
		"-t",
		"-i", opts.PrivateKeyPath,
		"-o", "StrictHostKeyChecking=accept-new",
		"-o", "UserKnownHostsFile=/dev/null",
		"-o", "LogLevel=ERROR",
		"-p", opts.Port,
		fmt.Sprintf("%s@localhost", opts.User),
	}

	if len(opts.Command) > 0 {
		sshArgs = append(sshArgs, opts.Command...)
	}

	return exec.Command("ssh", sshArgs...), nil
}

// DryRunSSH returns the SSH command formatted for dry-run output
func DryRunSSH(opts ConnectOptions) string {
	if opts.User == "" {
		opts.User = "sklein"
	}

	var cmd strings.Builder
	cmd.WriteString("ssh -t \\\n")
	cmd.WriteString(fmt.Sprintf("  -i %s \\\n", opts.PrivateKeyPath))
	cmd.WriteString("  -o StrictHostKeyChecking=accept-new \\\n")
	cmd.WriteString("  -o UserKnownHostsFile=/dev/null \\\n")
	cmd.WriteString("  -o LogLevel=ERROR \\\n")
	cmd.WriteString(fmt.Sprintf("  -p %s \\\n", opts.Port))
	cmd.WriteString(fmt.Sprintf("  %s@localhost", opts.User))

	if len(opts.Command) > 0 {
		cmd.WriteString(" \\\n")
		for i, arg := range opts.Command {
			if i < len(opts.Command)-1 {
				cmd.WriteString(fmt.Sprintf("  %s \\\n", arg))
			} else {
				cmd.WriteString(fmt.Sprintf("  %s", arg))
			}
		}
	}

	return cmd.String()
}

// WaitForSSH waits for the SSH server to be ready
func WaitForSSH(port, privateKeyPath string, maxAttempts int) error {
	for i := 0; i < maxAttempts; i++ {
		cmd := exec.Command("ssh",
			"-i", privateKeyPath,
			"-o", "StrictHostKeyChecking=accept-new",
			"-o", "UserKnownHostsFile=/dev/null",
			"-o", "LogLevel=ERROR",
			"-o", "ConnectTimeout=1",
			"-p", port,
			"sklein@localhost",
			"healthcheck",
		)

		if err := cmd.Run(); err == nil {
			return nil
		}

		// Wait before retry
		exec.Command("sleep", "0.5").Run()
	}

	return fmt.Errorf("SSH server not ready after %d attempts", maxAttempts)
}
