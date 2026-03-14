package main

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"

	"github.com/spf13/cobra"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

func init() {
	rootCmd.AddCommand(enterCmd)
}

var enterCmd = &cobra.Command{
	Use:   "enter",
	Short: "Enter the sklein-devbox container",
	Long:  `Launch an interactive shell inside the sklein-devbox container.`,
	Run: func(cmd *cobra.Command, args []string) {
		runEnter()
	},
}

func runEnter() {
	homeDir, err := getHomeDir()
	if err != nil {
		printError("Failed to determine home directory: %v", err)
		os.Exit(1)
	}

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	if err := podman.Run(homeDir, cwd); err != nil {
		printError("%v", err)
		os.Exit(1)
	}
}

func getHomeDir() (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	homeDir := filepath.Join(usr.HomeDir, ".local", "share", "sklein-devbox", "default")

	if err := os.MkdirAll(homeDir, 0755); err != nil {
		return "", err
	}

	return homeDir, nil
}

func printError(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
}
