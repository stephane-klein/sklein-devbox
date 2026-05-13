package main

import (
	"fmt"
	"os"
	"os/exec"

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

// stopAndRemoveContainer stops and removes the container for the given instance.
// It returns true if a container was found (and stopped/removed).
// It returns false if no container exists (not an error).
// Errors are returned for actual failures.
func stopAndRemoveContainer(instanceName, cwd string) (bool, error) {
	// Handle dry-run
	if viper.GetBool("dry-run") {
		dryRunCmd := podman.DryRunStopContainer(instanceName, cwd)
		fmt.Println(dryRunCmd)
		return true, nil
	}

	// Find container
	containerID, running, err := podman.FindContainer(instanceName, cwd)
	if err != nil {
		return false, fmt.Errorf("failed to check container status: %w", err)
	}

	if containerID == "" {
		return false, nil
	}

	if !running {
		fmt.Printf("Container %s is already stopped, removing...\n", containerID[:12])
		if err := podman.StopContainer(containerID); err != nil {
			return true, fmt.Errorf("failed to remove container: %w", err)
		}
		fmt.Println("Container removed.")
		return true, nil
	}

	// Stop the container
	fmt.Printf("Stopping container %s...\n", containerID[:12])

	podmanPath, err := podman.GetPodmanBinPath()
	if err != nil {
		return true, err
	}

	stopCmd := exec.Command(podmanPath, "stop", "-t", "30", containerID)
	if output, err := stopCmd.CombinedOutput(); err != nil {
		return true, fmt.Errorf("failed to stop container: %w\n%s", err, string(output))
	}

	// Wait for container to actually stop (poll every 2s, up to 15 attempts)
	fmt.Print("Waiting for container to stop")
	if err := podman.WaitContainerStopped(containerID, 15); err != nil {
		fmt.Println()
		return true, err
	}
	fmt.Println(" stopped!")

	// Remove the container
	rmCmd := exec.Command(podmanPath, "rm", containerID)
	if output, err := rmCmd.CombinedOutput(); err != nil {
		return true, fmt.Errorf("failed to remove container: %w\n%s", err, string(output))
	}

	fmt.Println("Container stopped and removed.")
	return true, nil
}

func runDown() {
	instanceName := getName()

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	found, err := stopAndRemoveContainer(instanceName, cwd)
	if err != nil {
		printError("%v", err)
		os.Exit(1)
	}
	if !found {
		fmt.Printf("No container found for instance '%s'\n", instanceName)
	}
}
