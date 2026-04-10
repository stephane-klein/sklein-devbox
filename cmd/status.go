package main

import (
	"fmt"
	"os"
	"time"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
	"github.com/stephane-klein/sklein-devbox/pkg/ssh"
)

func init() {
	rootCmd.AddCommand(statusCmd)
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show container status",
	Long:  `Displays container state, SSH port, uptime, and other information.`,
	Run: func(cmd *cobra.Command, args []string) {
		runStatus()
	},
}

func runStatus() {
	if viper.GetBool("dry-run") {
		fmt.Fprintln(os.Stderr, "Error: --dry-run is not implemented for the 'status' command")
		os.Exit(1)
	}

	instanceName := getName()

	status, err := podman.GetContainerStatus(instanceName)
	if err != nil {
		printError("Failed to get container status: %v", err)
		os.Exit(1)
	}

	if status == nil {
		fmt.Printf("Instance: %s\n", instanceName)
		fmt.Println("Status: not created")
		fmt.Println("\nRun 'sklein-devbox up' to start the container.")
		os.Exit(0)
	}

	fmt.Printf("Instance: %s\n", instanceName)
	fmt.Printf("Container ID: %s\n", status.ID[:12])
	fmt.Printf("Status: %s\n", formatStatus(status.Running))

	if status.Running {
		fmt.Printf("SSH Port: %s\n", status.SSHPort)
		if !status.StartedAt.IsZero() {
			uptime := time.Since(status.StartedAt)
			fmt.Printf("Uptime: %s\n", formatDuration(uptime))
		}
	} else if status.ExitCode != 0 {
		fmt.Printf("Exit Code: %d\n", status.ExitCode)
	}

	// Get paths
	homeDir, _ := podman.GetHomeDir(instanceName)
	workspaceDir, _ := os.Getwd()
	sshDir, _ := ssh.GetSSHDir()
	sshHostKeysDir, _ := ssh.GetSSHHostKeysDir()

	fmt.Println("\nPaths:")
	fmt.Printf("  Home:       %s\n", homeDir)
	fmt.Printf("  Workspace:  %s\n", workspaceDir)
	fmt.Printf("  SSH Keys:   %s\n", sshDir)
	fmt.Printf("  Host Keys:  %s\n", sshHostKeysDir)
}

func formatStatus(running bool) string {
	if running {
		return "running"
	}
	return "stopped"
}

func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%d seconds", int(d.Seconds()))
	}
	if d < time.Hour {
		return fmt.Sprintf("%d minutes", int(d.Minutes()))
	}
	if d < 24*time.Hour {
		return fmt.Sprintf("%d hours", int(d.Hours()))
	}
	return fmt.Sprintf("%d days", int(d.Hours()/24))
}
