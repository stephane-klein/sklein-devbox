package main

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"strings"
	"text/tabwriter"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

func init() {
	rootCmd.AddCommand(listCmd)
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all sklein-devbox instances",
	Long:  `List all existing sklein-devbox instances with their paths and container status.`,
	Run: func(cmd *cobra.Command, args []string) {
		runList()
	},
}

func runList() {
	if viper.GetBool("dry-run") {
		fmt.Fprintln(os.Stderr, "Error: --dry-run is not implemented for the 'list' command")
		os.Exit(1)
	}

	usr, err := user.Current()
	if err != nil {
		printError("Failed to get current user: %v", err)
		os.Exit(1)
	}

	baseDir := filepath.Join(usr.HomeDir, ".local", "share", "sklein-devbox", "instances")

	// Get all containers to check their status
	containers, err := podman.GetAllContainers()
	if err != nil {
		containers = []podman.ContainerStatus{}
	}

	// Build a map of instance name to container status
	containerMap := make(map[string]*podman.ContainerStatus)
	for i := range containers {
		// Extract instance name from container name (sklein-devbox-<instance>)
		name := containers[i].Name
		if strings.HasPrefix(name, "sklein-devbox-") {
			instanceName := strings.TrimPrefix(name, "sklein-devbox-")
			containerMap[instanceName] = &containers[i]
		}
	}

	// Create tabwriter for aligned output
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 4, ' ', 0)
	defer w.Flush()

	entries, err := os.ReadDir(baseDir)
	if err != nil {
		if os.IsNotExist(err) {
			// Check if there are containers without home directories
			if len(containers) > 0 {
				fmt.Fprintln(w, "NAME\tCONTAINER ID\tSTATUS\tSSH PORT\tPATH")
				fmt.Fprintln(w, "----\t------\t------\t--------\t----")
				for name, container := range containerMap {
					status := "stopped"
					port := "-"
					if container.Running {
						status = "running"
						port = container.SSHPort
					}
					containerID := "-"
					if container.ID != "" {
						containerID = container.ID[:6]
					}
					fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", name, containerID, status, port, "(no home directory)")
				}
				return
			}
			fmt.Println("No instances found.")
			return
		}
		printError("Failed to read directory: %v", err)
		os.Exit(1)
	}

	fmt.Fprintln(w, "NAME\tCONTAINER ID\tSTATUS\tSSH PORT\tPATH")
	fmt.Fprintln(w, "----\t------\t------\t--------\t----")

	found := false
	for _, entry := range entries {
		if entry.IsDir() {
			instanceName := entry.Name()
			instancePath := filepath.Join(baseDir, instanceName)

			// Check container status
			status := "not created"
			port := "-"
			containerID := "-"
			if container, exists := containerMap[instanceName]; exists {
				if container.ID != "" {
					containerID = container.ID
				}
				if container.Running {
					status = "running"
					port = container.SSHPort
				} else {
					status = "stopped"
				}
			}

			fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", instanceName, containerID, status, port, instancePath)
			found = true
		}
	}

	if !found {
		fmt.Println("No instances found.")
	}
}
