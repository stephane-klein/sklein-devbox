package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

func init() {
	rootCmd.AddCommand(destroyCmd)
}

var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy the sklein-devbox data directory",
	Long:  `Remove the ~/.local/share/sklein-devbox/instances/<name> directory.`,
	Run: func(cmd *cobra.Command, args []string) {
		runDestroy(force)
	},
}

var force bool

func init() {
	destroyCmd.Flags().BoolVarP(&force, "force", "f", false, "Skip confirmation prompt")
}

func runDestroy(force bool) {
	if viper.GetBool("dry-run") {
		fmt.Fprintln(os.Stderr, "Error: --dry-run is not implemented for the 'destroy' command")
		os.Exit(1)
	}

	instanceName := getName()

	// First, stop and remove the container if it exists
	containerID, _, err := podman.FindContainer(instanceName)
	if err != nil {
		printError("Failed to check container status: %v", err)
		os.Exit(1)
	}

	if containerID != "" {
		if !force {
			fmt.Printf("Container %s will be stopped and removed.\n", containerID[:12])
		}
		if err := podman.StopContainer(containerID); err != nil {
			printError("Failed to stop container: %v", err)
			// Continue anyway to try removing the home directory
		}
	}

	homeDir, err := podman.GetHomeDir(instanceName)
	if err != nil {
		printError("Failed to determine home directory: %v", err)
		os.Exit(1)
	}

	if !force {
		fmt.Printf("This will delete %s\n", homeDir)
		fmt.Print("Are you sure? [y/N]: ")

		var response string
		fmt.Scanln(&response)
		if response != "y" && response != "Y" {
			fmt.Println("Aborted.")
			os.Exit(0)
		}
	}

	if err := os.RemoveAll(homeDir); err != nil {
		printError("Failed to remove directory: %v", err)
		os.Exit(1)
	}

	fmt.Printf("Instance '%s' has been destroyed.\n", instanceName)
	if containerID != "" {
		fmt.Printf("Container %s stopped and removed.\n", containerID[:12])
	}
	fmt.Printf("Home directory %s removed.\n", homeDir)
}
