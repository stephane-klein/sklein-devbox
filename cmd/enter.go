package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

func init() {
	rootCmd.AddCommand(enterCmd)

	enterCmd.Flags().Bool("dry-run", false, "Print the podman command without executing")
}

var enterCmd = &cobra.Command{
	Use:   "enter",
	Short: "Enter the sklein-devbox container",
	Long:  `Launch an interactive shell inside the sklein-devbox container.`,
	Run: func(cmd *cobra.Command, args []string) {
		runEnter(cmd)
	},
}

func runEnter(cmd *cobra.Command) {
	instanceName := getName()

	homeDir, err := podman.GetHomeDir(instanceName)
	if err != nil {
		printError("Failed to determine home directory: %v", err)
		os.Exit(1)
	}

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	secrets := getSecretOptions()

	if cmd.Flag("dry-run").Changed {
		args := podman.BuildRunArgs(homeDir, cwd, instanceName, secrets, []string{})
		podman.DryRunCmd("podman", args)
		return
	}

	if err := podman.Run(homeDir, cwd, instanceName, secrets); err != nil {
		printError("%v", err)
		os.Exit(1)
	}
}

func printError(format string, args ...interface{}) {
	fmt.Fprintf(os.Stderr, "Error: "+format+"\n", args...)
}
