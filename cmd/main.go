package main

import (
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
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

func init() {
	cobra.OnInitialize(initConfig)

	rootCmd.PersistentFlags().StringP("name", "n", "", "Instance name")
	viper.BindPFlag("name", rootCmd.PersistentFlags().Lookup("name"))
	viper.BindEnv("name", "SKLEIN_DEVBOX_NAME")
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
