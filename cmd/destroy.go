package main

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

func init() {
	rootCmd.AddCommand(destroyCmd)
}

var destroyCmd = &cobra.Command{
	Use:   "destroy",
	Short: "Destroy the sklein-devbox data directory",
	Long:  `Remove the ~/.local/share/sklein-devbox/<name> directory.`,
	Run: func(cmd *cobra.Command, args []string) {
		runDestroy(force)
	},
}

var force bool

func init() {
	destroyCmd.Flags().BoolVarP(&force, "force", "f", false, "Skip confirmation prompt")
}

func runDestroy(force bool) {
	homeDir, err := getHomeDir(name)
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

	fmt.Printf("Directory %s has been destroyed.\n", homeDir)
}
