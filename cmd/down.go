package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

func init() {
	rootCmd.AddCommand(downCmd)
}

var downCmd = &cobra.Command{
	Use:   "down",
	Short: "Stop the sklein-devbox container",
	Long:  `Stops and removes the container for the specified instance.`,
	Run: func(cmd *cobra.Command, args []string) {
		runDown()
	},
}

func runDown() {
	instanceName := getName()

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	// Handle dry-run
	if viper.GetBool("dry-run") {
		dryRunCmd := podman.DryRunStopContainer(instanceName, cwd)
		fmt.Println(dryRunCmd)
		return
	}

	// Find container
	containerID, running, err := podman.FindContainer(instanceName, cwd)
	if err != nil {
		printError("Failed to check container status: %v", err)
		os.Exit(1)
	}

	if containerID == "" {
		fmt.Printf("No container found for instance '%s'\n", instanceName)
		os.Exit(0)
	}

	if !running {
		fmt.Printf("Container %s is already stopped, removing...\n", containerID[:12])
		if err := podman.StopContainer(containerID); err != nil {
			printError("Failed to remove container: %v", err)
			os.Exit(1)
		}
		fmt.Println("Container removed.")
		os.Exit(0)
	}

	// Stop the container
	fmt.Printf("Stopping container %s...\n", containerID[:12])
	if err := podman.StopContainer(containerID); err != nil {
		printError("Failed to stop container: %v", err)
		os.Exit(1)
	}

	fmt.Println("Container stopped and removed.")
}
