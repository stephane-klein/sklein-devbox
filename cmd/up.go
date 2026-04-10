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
	rootCmd.AddCommand(upCmd)
}

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "Start the sklein-devbox container",
	Long:  `Starts the container in detached mode with SSH access enabled.`,
	Run: func(cmd *cobra.Command, args []string) {
		runUp()
	},
}

func runUp() {
	instanceName := getName()

	// Get directories
	homeDir, err := podman.GetHomeDir(instanceName)
	if err != nil {
		printError("Failed to determine home directory: %v", err)
		os.Exit(1)
	}

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	secrets := getSecretOptions()

	// Handle dry-run
	if viper.GetBool("dry-run") {
		dryRunCmd, err := podman.DryRunStartContainer(homeDir, cwd, instanceName, secrets)
		if err != nil {
			printError("%v", err)
			os.Exit(1)
		}
		fmt.Println(dryRunCmd)
		return
	}

	// Ensure SSH keys exist
	if err := ssh.EnsureSSHKeys(); err != nil {
		printError("Failed to ensure SSH keys: %v", err)
		os.Exit(1)
	}

	// Check if container already exists and is running
	containerID, running, err := podman.FindContainer(instanceName)
	if err != nil {
		printError("Failed to check container status: %v", err)
		os.Exit(1)
	}

	if running {
		sshPort, err := podman.GetContainerSSHPort(containerID)
		if err == nil {
			fmt.Printf("Container already running: %s (SSH port: %s)\n", containerID[:12], sshPort)
			os.Exit(0)
		}
	}

	// Start container
	fmt.Printf("Starting container for instance '%s'...\n", instanceName)
	containerID, sshPort, err := podman.StartContainer(homeDir, cwd, instanceName, secrets)
	if err != nil {
		printError("Failed to start container: %v", err)
		os.Exit(1)
	}

	// Get SSH key paths for the wait check
	privateKeyPath, _, err := ssh.GetKeyPaths()
	if err != nil {
		printError("Failed to get SSH key paths: %v", err)
		os.Exit(1)
	}

	// Wait for SSH to be ready
	fmt.Print("Waiting for SSH server...")
	if err := ssh.WaitForSSH(sshPort, privateKeyPath, 30); err != nil {
		fmt.Println()
		printError("SSH server failed to start: %v", err)
		// Clean up container
		podman.StopContainer(containerID)
		os.Exit(1)
	}
	fmt.Println(" ready!")

	fmt.Printf("Container started: %s (SSH port: %s)\n", containerID[:12], sshPort)
}
