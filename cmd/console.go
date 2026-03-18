package main

import (
	"fmt"
	"os"
	"os/exec"

	"github.com/spf13/cobra"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

func init() {
	rootCmd.AddCommand(consoleCmd)
}

var consoleCmd = &cobra.Command{
	Use:   "console",
	Short: "Open a tmux session in the devbox container with Alacritty",
	Long: `Launch Alacritty and connect to a tmux session inside the sklein-devbox container.
If a tmux session named "devbox" already exists, it will attach to it.
Otherwise, a new session will be created.`,
	Run: func(cmd *cobra.Command, args []string) {
		runConsole()
	},
}

func runConsole() {
	instanceName := getName()

	alacrittyPath, err := exec.LookPath("alacritty")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: Alacritty is not installed on your system.\n")
		fmt.Fprintf(os.Stderr, "Please install Alacritty to use the 'console' command.\n")
		fmt.Fprintf(os.Stderr, "On Fedora: sudo dnf install alacritty\n")
		os.Exit(1)
	}

	podmanBinPath, err := podman.GetPodmanBinPath()
	if err != nil {
		printError("%v", err)
		os.Exit(1)
	}

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

	podmanArgs := podman.BuildRunArgs(homeDir, cwd, instanceName, []string{"/bin/zsh", "-i", "-c", "tmux new-session -A -s devbox"})

	alacrittyCmd := exec.Command(alacrittyPath, append([]string{"-e", podmanBinPath}, podmanArgs...)...)
	alacrittyCmd.Stdin = os.Stdin
	alacrittyCmd.Stdout = os.Stdout
	alacrittyCmd.Stderr = os.Stderr

	if err := alacrittyCmd.Run(); err != nil {
		printError("Failed to launch Alacritty: %v", err)
		os.Exit(1)
	}
}
