package main

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"github.com/stephane-klein/sklein-devbox/pkg/podman"
)

var version = "dev"

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

func init() {
	cobra.OnInitialize(initConfig)

	rootCmd.PersistentFlags().StringP("name", "n", "", "Instance name")
	viper.BindPFlag("name", rootCmd.PersistentFlags().Lookup("name"))
	viper.BindEnv("name", "SKLEIN_DEVBOX_NAME")

	rootCmd.PersistentFlags().Bool("gopass", false, "Enable gopass integration")
	rootCmd.PersistentFlags().Bool("no-gopass-mount", false, "Disable auto-mount of host gopass directories")
	rootCmd.PersistentFlags().Bool("no-ssh-mount", false, "Disable auto-mount of host ~/.ssh")
	rootCmd.PersistentFlags().String("ssh-key-file", "", "Path to SSH private key for secrets repository")
	rootCmd.PersistentFlags().String("age-key-file", "", "Path to Age identity key for gopass")

	viper.BindPFlag("gopass", rootCmd.PersistentFlags().Lookup("gopass"))
	viper.BindPFlag("no-gopass-mount", rootCmd.PersistentFlags().Lookup("no-gopass-mount"))
	viper.BindPFlag("no-ssh-mount", rootCmd.PersistentFlags().Lookup("no-ssh-mount"))
	viper.BindPFlag("ssh-key-file", rootCmd.PersistentFlags().Lookup("ssh-key-file"))
	viper.BindPFlag("age-key-file", rootCmd.PersistentFlags().Lookup("age-key-file"))

	viper.BindEnv("gopass", "SKLEIN_DEVBOX_GOPASS")
	viper.BindEnv("no-gopass-mount", "SKLEIN_DEVBOX_NO_GOPASS_MOUNT")
	viper.BindEnv("no-ssh-mount", "SKLEIN_DEVBOX_NO_SSH_MOUNT")
	viper.BindEnv("ssh-key-file", "SKLEIN_DEVBOX_SSH_KEY_FILE")
	viper.BindEnv("age-key-file", "SKLEIN_DEVBOX_AGE_KEY_FILE")

	rootCmd.PersistentFlags().Bool("disable-init", false, "Disable initialization on entry")
	viper.BindPFlag("disable-init", rootCmd.PersistentFlags().Lookup("disable-init"))
	viper.BindEnv("disable-init", "SKLEIN_DEVBOX_DISABLE_INIT")

	rootCmd.PersistentFlags().Bool("dry-run", false, "Print commands without executing")
	viper.BindPFlag("dry-run", rootCmd.PersistentFlags().Lookup("dry-run"))

	rootCmd.PersistentFlags().String("from", "", "Create new instance from an existing instance's home directory")
	viper.BindPFlag("from", rootCmd.PersistentFlags().Lookup("from"))
	viper.BindEnv("from", "SKLEIN_DEVBOX_FROM")

	rootCmd.PersistentFlags().String("mise-cache-dir", "", "Path to mise installs cache directory (default: ~/.local/share/mise/installs/)")
	rootCmd.PersistentFlags().Bool("no-mise-cache-mount", false, "Disable mounting of host mise installs cache directory")

	viper.BindPFlag("mise-cache-dir", rootCmd.PersistentFlags().Lookup("mise-cache-dir"))
	viper.BindPFlag("no-mise-cache-mount", rootCmd.PersistentFlags().Lookup("no-mise-cache-mount"))

	viper.BindEnv("mise-cache-dir", "SKLEIN_DEVBOX_MISE_CACHE_DIR")
	viper.BindEnv("no-mise-cache-mount", "SKLEIN_DEVBOX_NO_MISE_CACHE_MOUNT")

	rootCmd.PersistentFlags().Bool("no-pulse-audio", false, "Disable PulseAudio socket mount")
	viper.BindPFlag("no-pulse-audio", rootCmd.PersistentFlags().Lookup("no-pulse-audio"))
	viper.BindEnv("no-pulse-audio", "SKLEIN_DEVBOX_NO_PULSE_AUDIO")
}

func initConfig() {
	viper.SetDefault("name", "default")

	homeDir, err := os.UserHomeDir()
	if err == nil {
		globalConfigDir := filepath.Join(homeDir, ".config", "sklein-devbox")
		viper.AddConfigPath(globalConfigDir)
		viper.SetConfigName("config")
		viper.SetConfigType("toml")
		if err := viper.ReadInConfig(); err != nil && !isConfigNotFoundError(err) {
			printError("Failed to read global config file: %v", err)
			os.Exit(1)
		}
	}

	viper.AddConfigPath(".")
	viper.SetConfigName(".sklein-devbox")
	viper.SetConfigType("toml")
	if err := viper.MergeInConfig(); err != nil && !isConfigNotFoundError(err) {
		printError("Failed to read local config file: %v", err)
		os.Exit(1)
	}
}

func isConfigNotFoundError(err error) bool {
	_, ok := err.(viper.ConfigFileNotFoundError)
	return ok
}

func getName() string {
	return viper.GetString("name")
}

func getDisableInit() bool {
	return viper.GetBool("disable-init")
}

func expandPath(path string) string {
	if path != "" && strings.HasPrefix(path, "~/") {
		if home, err := os.UserHomeDir(); err == nil {
			return filepath.Join(home, path[2:])
		}
	}
	return path
}

func getContainerOptions() *podman.ContainerOptions {
	return &podman.ContainerOptions{
		Gopass:           viper.GetBool("gopass"),
		NoGopassMount:    viper.GetBool("no-gopass-mount"),
		NoSshMount:       viper.GetBool("no-ssh-mount"),
		NoMiseCacheMount: viper.GetBool("no-mise-cache-mount"),
		NoPulseAudio:     viper.GetBool("no-pulse-audio"),
		SshKeyFile:       expandPath(viper.GetString("ssh-key-file")),
		AgeKeyFile:       expandPath(viper.GetString("age-key-file")),
		MiseCacheDir:     expandPath(viper.GetString("mise-cache-dir")),
	}
}
