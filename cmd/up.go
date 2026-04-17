package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	cp "github.com/otiai10/copy"
	"github.com/schollz/progressbar/v3"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
	"github.com/stephane-klein/sklein-devbox/pkg/ssh"
)

func init() {
	rootCmd.AddCommand(upCmd)
}

var upCmd = &cobra.Command{
	Use:   "up",
	Short: "Start the sklein-devbox container",
	Long:  `Starts the container in detached mode with SSH access enabled.`,
	Run: func(cmd *cobra.Command, args []string) {
		runUp()
	},
}

func runUp() {
	instanceName := getName()
	fromInstance := viper.GetString("from")

	_, exists, _ := podman.FindContainer(instanceName)
	if exists {
		if fromInstance != "" {
			fmt.Fprintf(os.Stderr, "Instance %q already exists, ignoring --from flag (only used at creation)\n", instanceName)
		}
	} else if fromInstance != "" {
		if err := copyInstanceHome(fromInstance, instanceName); err != nil {
			printError("Failed to copy from instance %q: %v", fromInstance, err)
			os.Exit(1)
		}
	}

	// Get directories
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

	// Handle dry-run
	if viper.GetBool("dry-run") {
		dryRunCmd, err := podman.DryRunStartContainer(homeDir, cwd, instanceName, secrets)
		if err != nil {
			printError("%v", err)
			os.Exit(1)
		}
		fmt.Println(dryRunCmd)
		return
	}

	// Ensure SSH keys exist
	if err := ssh.EnsureSSHKeys(); err != nil {
		printError("Failed to ensure SSH keys: %v", err)
		os.Exit(1)
	}

	// Check if container already exists and is running
	containerID, running, err := podman.FindContainer(instanceName)
	if err != nil {
		printError("Failed to check container status: %v", err)
		os.Exit(1)
	}

	if running {
		sshPort, err := podman.GetContainerSSHPort(containerID)
		if err == nil {
			fmt.Printf("Container already running: %s (SSH port: %s)\n", containerID[:12], sshPort)
			os.Exit(0)
		}
	}

	// Start container
	fmt.Printf("Starting container for instance '%s'...\n", instanceName)
	containerID, sshPort, err := podman.StartContainer(homeDir, cwd, instanceName, secrets)
	if err != nil {
		printError("Failed to start container: %v", err)
		os.Exit(1)
	}

	// Get SSH key paths for the wait check
	privateKeyPath, _, err := ssh.GetKeyPaths()
	if err != nil {
		printError("Failed to get SSH key paths: %v", err)
		os.Exit(1)
	}

	// Wait for SSH to be ready
	fmt.Print("Waiting for SSH server...")
	if err := ssh.WaitForSSH(sshPort, privateKeyPath, 30); err != nil {
		fmt.Println()
		printError("SSH server failed to start: %v", err)
		// Clean up container
		podman.StopContainer(containerID)
		os.Exit(1)
	}
	fmt.Println(" ready!")

	fmt.Printf("Container started: %s (SSH port: %s)\n", containerID[:12], sshPort)
}

func copyInstanceHome(sourceName, targetName string) error {
	sourceHome, err := podman.GetHomeDir(sourceName)
	if err != nil {
		return fmt.Errorf("cannot access source instance %q home: %w", sourceName, err)
	}

	entries, err := os.ReadDir(sourceHome)
	if err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("source instance %q has no home directory", sourceName)
		}
		return err
	}

	if len(entries) == 0 {
		fmt.Fprintf(os.Stderr, "Warning: source instance %q has empty home directory\n", sourceName)
	}

	if _, running, _ := podman.FindContainer(sourceName); running {
		fmt.Fprintf(os.Stderr, "Warning: copying from running instance %q\n", sourceName)
	}

	totalSize, _, err := calculateTotalSize(sourceHome)
	if err != nil {
		return fmt.Errorf("failed to calculate source size: %w", err)
	}

	bar := progressbar.NewOptions64(totalSize,
		progressbar.OptionSetDescription(fmt.Sprintf("Copying from %s", sourceName)),
		progressbar.OptionShowBytes(true),
		progressbar.OptionShowCount(),
		progressbar.OptionSetWidth(40),
		progressbar.OptionSetRenderBlankState(true),
		progressbar.OptionThrottle(100*time.Millisecond),
	)

	opt := cp.Options{
		PreserveTimes:  true,
		PreserveOwner:  true,
		Sync:           false,
		CopyBufferSize: 256 * 1024,
		Skip: func(info os.FileInfo, src, dest string) (bool, error) {
			mode := info.Mode()
			if mode&os.ModeSocket != 0 ||
				mode&os.ModeDevice != 0 ||
				mode&os.ModeNamedPipe != 0 {
				return true, nil
			}
			return false, nil
		},
		WrapReader: func(src io.Reader) io.Reader {
			return &ProgressReader{src: src, bar: bar}
		},
	}

	targetHome, err := podman.GetHomeDir(targetName)
	if err != nil {
		return err
	}

	if err := cp.Copy(sourceHome, targetHome, opt); err != nil {
		return fmt.Errorf("copy failed: %w", err)
	}

	bar.Finish()
	fmt.Println()

	return nil
}

type ProgressReader struct {
	src io.Reader
	bar *progressbar.ProgressBar
}

func (r *ProgressReader) Read(p []byte) (int, error) {
	n, err := r.src.Read(p)
	if n > 0 {
		r.bar.Add(n)
	}
	return n, err
}

func calculateTotalSize(root string) (int64, int, error) {
	var totalSize int64
	var fileCount int

	err := filepath.WalkDir(root, func(path string, d os.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if !d.IsDir() {
			info, err := d.Info()
			if err == nil {
				totalSize += info.Size()
				fileCount++
			}
		}
		return nil
	})

	return totalSize, fileCount, err
}
