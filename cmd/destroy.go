package main

import (
	"fmt"
	"os"
	"os/user"
	"strings"

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

func shortenPath(path string) string {
	usr, err := user.Current()
	if err != nil {
		return path
	}
	if strings.HasPrefix(path, usr.HomeDir) {
		return "~" + strings.TrimPrefix(path, usr.HomeDir)
	}
	return path
}

func runDestroy(force bool) {
	if viper.GetBool("dry-run") {
		fmt.Fprintln(os.Stderr, "Error: --dry-run is not implemented for the 'destroy' command")
		os.Exit(1)
	}

	instanceName := getName()

	// Check if any containers are still using this home directory
	containers, err := podman.FindAllContainersForHomeName(instanceName)
	if err != nil {
		printError("Failed to check container status: %v", err)
		os.Exit(1)
	}

	if len(containers) > 0 {
		fmt.Fprintf(os.Stderr, "Error: Cannot destroy home directory '%s' because it is still in use by the following containers:\n", instanceName)
		for _, container := range containers {
			workspace := container.Workspace
			if workspace == "" {
				workspace = "(unknown)"
			} else {
				workspace = shortenPath(workspace)
			}
			fmt.Fprintf(os.Stderr, "  - %s  (workspace: %s)\n", container.Name, workspace)
		}
		fmt.Fprintln(os.Stderr, "Please stop these containers first with 'sklein-devbox down' in each workspace.")
		os.Exit(1)
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
	fmt.Printf("Home directory %s removed.\n", homeDir)
}
