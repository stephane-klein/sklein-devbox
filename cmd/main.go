package main

import (
	"os"

	"github.com/spf13/cobra"
)

var version = "0.1.0"

func main() {
	if err := rootCmd.Execute(); err != nil {
		os.Exit(1)
	}
}

var rootCmd = &cobra.Command{
	Use:     "sklein-devbox",
	Short:   "A Podman-based development environment",
	Long:    `sklein-devbox launches a containerized development environment using Podman.`,
	Version: version,
}

var name string

func init() {
	rootCmd.PersistentFlags().StringVarP(&name, "name", "n", "default", "Instance name")
}
