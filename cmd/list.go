package main

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(listCmd)
}

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all sklein-devbox instances",
	Long:  `List all existing sklein-devbox instances with their paths.`,
	Run: func(cmd *cobra.Command, args []string) {
		runList()
	},
}

func runList() {
	usr, err := user.Current()
	if err != nil {
		printError("Failed to get current user: %v", err)
		os.Exit(1)
	}

	baseDir := filepath.Join(usr.HomeDir, ".local", "share", "sklein-devbox")

	entries, err := os.ReadDir(baseDir)
	if err != nil {
		if os.IsNotExist(err) {
			fmt.Println("No instances found.")
			return
		}
		printError("Failed to read directory: %v", err)
		os.Exit(1)
	}

	found := false
	for _, entry := range entries {
		if entry.IsDir() {
			instancePath := filepath.Join(baseDir, entry.Name())
			fmt.Printf("%s  %s\n", entry.Name(), instancePath)
			found = true
		}
	}

	if !found {
		fmt.Println("No instances found.")
	}
}
