package main

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"sort"
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

type listRow struct {
	HomeName    string
	Workspace   string
	ContainerID string
	Status      string
	SSHPort     string
	HomePath    string
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

	// Get all containers
	containers, err := podman.GetAllContainers()
	if err != nil {
		containers = []podman.ContainerStatus{}
	}

	// Get all home directories
	homeDirs := make(map[string]string) // homeName -> path
	entries, err := os.ReadDir(baseDir)
	if err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				name := entry.Name()
				homeDirs[name] = filepath.Join(baseDir, name)
			}
		}
	}

	// Build rows
	var rows []listRow
	homeHasContainers := make(map[string]bool)

	for _, c := range containers {
		homeName := c.HomeName
		if homeName == "" {
			homeName = "(orphan)"
		}
		homeHasContainers[homeName] = true

		status := "stopped"
		port := "-"
		if c.Running {
			status = "running"
			port = c.SSHPort
		}

		containerID := "-"
		if c.ID != "" {
			containerID = c.ID[:12]
		}

		workspace := c.Workspace
		if workspace == "" {
			workspace = "-"
		} else {
			workspace = shortenPath(workspace)
		}

		homePath := homeDirs[homeName]
		if homePath == "" {
			homePath = "(no home directory)"
		}

		rows = append(rows, listRow{
			HomeName:    homeName,
			Workspace:   workspace,
			ContainerID: containerID,
			Status:      status,
			SSHPort:     port,
			HomePath:    homePath,
		})
	}

	// Add home directories without containers
	for homeName, homePath := range homeDirs {
		if !homeHasContainers[homeName] {
			rows = append(rows, listRow{
				HomeName:    homeName,
				Workspace:   "-",
				ContainerID: "-",
				Status:      "not created",
				SSHPort:     "-",
				HomePath:    homePath,
			})
		}
	}

	// Sort by HomeName then Workspace
	sort.Slice(rows, func(i, j int) bool {
		if rows[i].HomeName != rows[j].HomeName {
			return rows[i].HomeName < rows[j].HomeName
		}
		return rows[i].Workspace < rows[j].Workspace
	})

	// Create tabwriter for aligned output
	w := tabwriter.NewWriter(os.Stdout, 0, 0, 4, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "HOME NAME\tWORKSPACE\tCONTAINER ID\tSTATUS\tSSH PORT\tHOME PATH")
	fmt.Fprintln(w, "---------\t---------\t------------\t------\t--------\t---------")

	for _, row := range rows {
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\n",
			row.HomeName, row.Workspace, row.ContainerID, row.Status, row.SSHPort, row.HomePath)
	}

	if len(rows) == 0 {
		fmt.Println("No instances found.")
	}
}
