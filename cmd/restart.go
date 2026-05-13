package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func init() {
	rootCmd.AddCommand(restartCmd)
}

var restartCmd = &cobra.Command{
	Use:   "restart",
	Short: "Restart the container (down + up)",
	Long:  `Stops and removes the container, then starts it again.`,
	Args:  cobra.NoArgs,
	Run: func(cmd *cobra.Command, args []string) {
		if viper.GetBool("dry-run") {
			fmt.Fprintf(os.Stderr, "Error: --dry-run is not supported by the restart command\n")
			os.Exit(1)
		}
		runRestart()
	},
}

func runRestart() {
	instanceName := getName()

	cwd, err := os.Getwd()
	if err != nil {
		printError("Failed to get current working directory: %v", err)
		os.Exit(1)
	}

	// Step 1: stop and remove existing container (if any)
	if _, err := stopAndRemoveContainer(instanceName, cwd); err != nil {
		printError("%v", err)
		os.Exit(1)
	}

	// Step 2: start container (prevent --from from overwriting existing home)
	viper.Set("from", "")
	runUp()
}
