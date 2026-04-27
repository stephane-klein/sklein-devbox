package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
	"github.com/stephane-klein/sklein-devbox/pkg/ssh"
)

func init() {
	rootCmd.AddCommand(enterCmd)
}

var enterCmd = &cobra.Command{
	Use:   "enter",
	Short: "Enter the sklein-devbox container",
	Long:  `Launch an interactive shell inside the sklein-devbox container via SSH. Starts the container if not running.`,
	Run: func(cmd *cobra.Command, args []string) {
		runEnter()
	},
}

func runEnter() {
	instanceName := getName()

	// Handle dry-run - print SSH command only
	if viper.GetBool("dry-run") {
		privateKeyPath, _, err := ssh.GetKeyPaths()
		if err != nil {
			printError("Failed to get SSH key paths: %v", err)
			os.Exit(1)
		}

		// For dry-run, we use a placeholder for the port
		connectOpts := ssh.ConnectOptions{
			Port:           "<port>",
			PrivateKeyPath: privateKeyPath,
			User:           "sklein",
		}

		dryRunCmd := ssh.DryRunSSH(connectOpts)
		fmt.Println(dryRunCmd)
		return
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

		secrets := getSecretOptions()

		containerID, sshPort, err = podman.StartContainer(homeDir, cwd, instanceName, secrets)
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

	// Connect via SSH (this replaces the current process)
	connectOpts := ssh.ConnectOptions{
		Port:           sshPort,
		PrivateKeyPath: privateKeyPath,
		User:           "sklein",
	}

	if err := ssh.Connect(connectOpts); err != nil {
		printError("Failed to connect via SSH: %v", err)
		os.Exit(1)
	}
}

func printError(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
}
