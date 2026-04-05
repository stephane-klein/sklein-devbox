package podman

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"syscall"
)

type SecretOptions struct {
	Gopass        bool
	NoGopassMount bool
	NoSshMount    bool
	SshKeyFile    string
	AgeKeyFile    string
}

func GetHomeDir(instanceName string) (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	homeDir := filepath.Join(usr.HomeDir, ".local", "share", "sklein-devbox", instanceName)

	if err := os.MkdirAll(homeDir, 0755); err != nil {
		return "", err
	}

	return homeDir, nil
}

func BuildRunArgs(homeDir, workspaceDir, instanceName string, secrets *SecretOptions, cmd []string) []string {
	args := []string{
		"run", "-it", "--rm",
		"--label=app=sklein-devbox",
		"--userns=keep-id",
		"--cap-add=SETUID",
		"--cap-add=SETGID",
		"-e", "TERM",
		"-e", "SKLEIN_DEVBOX_NAME=" + instanceName,
		"-v", workspaceDir + ":/workspace:U",
		"-v", homeDir + ":/home/sklein:U",
	}

	usr, _ := user.Current()
	home := usr.HomeDir

	if secrets.Gopass {
		args = append(args, "-e", "SKLEIN_DEVBOX_GOPASS=1")
	}

	if secrets.SshKeyFile != "" {
		args = append(args, "-v", secrets.SshKeyFile+":/tmp/sklein-devbox-ssh-key:ro")
	}

	if secrets.AgeKeyFile != "" {
		args = append(args, "-v", secrets.AgeKeyFile+":/tmp/sklein-devbox-age-key:ro")
	}

	if _, err := os.Stat(filepath.Join(home, ".ssh")); err == nil && !secrets.NoSshMount {
		args = append(args, "-v", filepath.Join(home, ".ssh")+":/home/sklein/.ssh:U")
	}

	hasGopass := false
	if _, err := os.Stat(filepath.Join(home, ".config", "gopass")); err == nil {
		hasGopass = true
	}
	if _, err := os.Stat(filepath.Join(home, ".local", "share", "gopass")); err == nil {
		hasGopass = true
	}

	if hasGopass && !secrets.NoGopassMount {
		args = append(args, "-v", filepath.Join(home, ".config", "gopass", "age", "identities")+":/home/sklein/.config/gopass/age/identities:U")
		args = append(args, "-v", filepath.Join(home, ".local", "share", "gopass")+":/home/sklein/.local/share/gopass:U")
	}

	args = append(args, "ghcr.io/stephane-klein/sklein-devbox:latest")

	args = append(args, cmd...)
	return args
}

func Run(homeDir, workspaceDir, instanceName string, secrets *SecretOptions) error {
	return RunWithCmd(homeDir, workspaceDir, instanceName, secrets, []string{})
}

func RunWithCmd(homeDir, workspaceDir, instanceName string, secrets *SecretOptions, cmd []string) error {
	if err := os.MkdirAll(homeDir, 0755); err != nil {
		return err
	}

	if secrets.Gopass && !secrets.NoGopassMount {
		gopassDirs := []string{
			filepath.Join(homeDir, ".config", "gopass", "age",),
			filepath.Join(homeDir, ".local", "share", "gopass"),
		}
		for _, dir := range gopassDirs {
			if err := os.MkdirAll(dir, 0755); err != nil {
				return err
			}
		}
	}

	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return err
	}

	args := []string{"podman"}
	args = append(args, BuildRunArgs(homeDir, workspaceDir, instanceName, secrets, cmd)...)

	env := os.Environ()

	err = syscall.Exec(podmanPath, args, env)
	return err
}

func DryRunCmd(bin string, args []string) {
	fmt.Print(bin, " ", args[0], " \\\n")
	for i := 1; i < len(args)-1; i++ {
		arg := args[i]
		if (arg == "-e" || arg == "-v" || arg == "--label") && i+1 < len(args) {
			fmt.Printf("  %s %s \\\n", arg, args[i+1])
			i++
		} else {
			fmt.Printf("  %s \\\n", arg)
		}
	}
	fmt.Printf("  %s\n", args[len(args)-1])
}
