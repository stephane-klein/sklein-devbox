package main

import (
	"os"

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

	rootCmd.PersistentFlags().Bool("dry-run", false, "Print commands without executing")
	viper.BindPFlag("dry-run", rootCmd.PersistentFlags().Lookup("dry-run"))
}

func initConfig() {
	viper.SetConfigName(".sklein-devbox")
	viper.AddConfigPath(".")
	viper.SetDefault("name", "default")

	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
			printError("Failed to read config file: %v", err)
			os.Exit(1)
		}
	}
}

func getName() string {
	return viper.GetString("name")
}

func getSecretOptions() *podman.SecretOptions {
	return &podman.SecretOptions{
		Gopass:        viper.GetBool("gopass"),
		NoGopassMount: viper.GetBool("no-gopass-mount"),
		NoSshMount:    viper.GetBool("no-ssh-mount"),
		SshKeyFile:    viper.GetString("ssh-key-file"),
		AgeKeyFile:    viper.GetString("age-key-file"),
	}
}
