package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/config"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
	"github.com/stephane-klein/sklein-devbox/pkg/ssh"
)

func init() {
	rootCmd.AddCommand(consoleCmd)
}

var consoleCmd = &cobra.Command{
	Use:   "console",
	Short: "Open a tmux session in the devbox container with a terminal emulator",
	Long: `Launch a terminal emulator (foot by default, or Alacritty) and connect to a
tmux session inside the sklein-devbox container via SSH.
If a tmux session named "devbox" already exists, it will attach to it.
Otherwise, a new session will be created.`,
	Run: func(cmd *cobra.Command, args []string) {
		runConsole()
	},
}

func runConsole() {
	instanceName := getName()
	terminal := getTerminal()

	if terminal != "foot" && terminal != "alacritty" {
		fmt.Fprintf(os.Stderr, "Error: invalid terminal %q. Use \"foot\" (default) or \"alacritty\".\n", terminal)
		os.Exit(1)
	}

	// Handle dry-run - print terminal + SSH command only
	if viper.GetBool("dry-run") {
		privateKeyPath, _, err := ssh.GetKeyPaths()
		if err != nil {
			printError("Failed to get SSH key paths: %v", err)
			os.Exit(1)
		}

		if terminal == "foot" {
			fmt.Println(`foot --config <temp-foot.ini> -e \`)
		} else {
			fmt.Println(`alacritty --option general.live_config_reload=false -e \`)
		}

		fmt.Printf("  ssh -t \\\n")
		fmt.Printf("    -i %s \\\n", privateKeyPath)
		fmt.Println(`    -o StrictHostKeyChecking=accept-new \`)
		fmt.Println(`    -o UserKnownHostsFile=/dev/null \`)
		fmt.Println(`    -o LogLevel=ERROR \`)
		if getDisableInit() {
			fmt.Println(`    -o SetEnv=SKLEIN_DEVBOX_DISABLE_INIT=1 \`)
		}
		fmt.Println(`    -p <port> \`)
		fmt.Println(`    sklein@localhost \`)
		fmt.Println("    \"sh -c 'cd /workspace && exec tmux new-session -A -s devbox'\"")
		return
	}

	// Locate terminal binary
	var termPath string
	var err error

	if terminal == "foot" {
		termPath, err = exec.LookPath("foot")
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: foot is not installed on your system.\n")
			fmt.Fprintf(os.Stderr, "Please install foot to use the 'console' command.\n")
			fmt.Fprintf(os.Stderr, "On Fedora: sudo dnf install foot\n")
			os.Exit(1)
		}
	} else {
		termPath, err = exec.LookPath("alacritty")
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: Alacritty is not installed on your system.\n")
			fmt.Fprintf(os.Stderr, "Please install Alacritty or switch to foot (default) to use the 'console' command.\n")
			fmt.Fprintf(os.Stderr, "On Fedora: sudo dnf install alacritty\n")
			os.Exit(1)
		}
	}

	// Ensure SSH keys exist
	if err := ssh.EnsureSSHKeys(); err != nil {
		printError("Failed to ensure SSH keys: %v", err)
		os.Exit(1)
	}

	privateKeyPath, _, err := ssh.GetKeyPaths()
	if err != nil {
		printError("Failed to get SSH key paths: %v", err)
		os.Exit(1)
	}

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	// Check if container is running
	containerID, running, err := podman.FindContainer(instanceName, cwd)
	if err != nil {
		printError("Failed to check container status: %v", err)
		os.Exit(1)
	}

	var sshPort string

	if !running {
		// Container not running, start it automatically
		fmt.Printf("Container for instance '%s' is not running. Starting...\n", instanceName)

		homeDir, err := podman.GetHomeDir(instanceName)
		if err != nil {
			printError("Failed to determine home directory: %v", err)
			os.Exit(1)
		}

		opts := getContainerOptions()

		// Pull the latest image
		if !opts.NoPullImage {
			fmt.Println("Pulling latest image...")
			if err := podman.PullImage(); err != nil {
				printError("Failed to pull image: %v", err)
				os.Exit(1)
			}
		}

		containerID, sshPort, err = podman.StartContainer(homeDir, cwd, instanceName, opts)
		if err != nil {
			printError("Failed to start container: %v", err)
			os.Exit(1)
		}

		// Wait for SSH to be ready
		fmt.Print("Waiting for SSH server...")
		if err := ssh.WaitForSSH(sshPort, privateKeyPath, 30); err != nil {
			fmt.Println()
			printError("SSH server failed to start: %v", err)
			podman.StopContainer(containerID)
			os.Exit(1)
		}
		fmt.Println(" ready!")
		fmt.Printf("Container started: %s (SSH port: %s)\n", containerID[:12], sshPort)
	} else {
		// Container is running, get its SSH port
		sshPort, err = podman.GetContainerSSHPort(containerID)
		if err != nil {
			printError("Failed to get SSH port: %v", err)
			os.Exit(1)
		}
	}

	// Build SSH command
	sshCmd := []string{
		"ssh",
		"-t",
		"-i", privateKeyPath,
		"-o", "StrictHostKeyChecking=accept-new",
		"-o", "UserKnownHostsFile=/dev/null",
		"-o", "LogLevel=ERROR",
	}

	if getDisableInit() {
		sshCmd = append(sshCmd, "-o", "SetEnv=SKLEIN_DEVBOX_DISABLE_INIT=1")
	}

	sshCmd = append(sshCmd,
		"-p", sshPort,
		"sklein@localhost",
		"sh -c 'cd /workspace && exec tmux new-session -A -s devbox'",
	)

	if terminal == "foot" {
		// Write embedded foot config to a temporary file
		tmpFile, err := os.CreateTemp("", "foot-*.ini")
		if err != nil {
			printError("Failed to create temporary foot config: %v", err)
			os.Exit(1)
		}
		defer os.Remove(tmpFile.Name())

		if _, err := tmpFile.WriteString(config.FootConfig); err != nil {
			printError("Failed to write foot config: %v", err)
			os.Exit(1)
		}
		if err := tmpFile.Close(); err != nil {
			printError("Failed to close foot config: %v", err)
			os.Exit(1)
		}

		termCmd := exec.Command(termPath, append([]string{"--config", tmpFile.Name(), "-d", "error", "-e"}, sshCmd...)...)
		termCmd.Stdin = os.Stdin
		termCmd.Stdout = os.Stdout
		termCmd.Stderr = os.Stderr

		if err := termCmd.Run(); err != nil {
			printError("Failed to launch foot: %v", err)
			os.Exit(1)
		}
	} else {
		termCmd := exec.Command(termPath, append([]string{"--option", "general.live_config_reload=false", "-e"}, sshCmd...)...)
		termCmd.Stdin = os.Stdin
		termCmd.Stdout = os.Stdout
		termCmd.Stderr = os.Stderr

		if err := termCmd.Run(); err != nil {
			printError("Failed to launch Alacritty: %v", err)
			os.Exit(1)
		}
	}
}
