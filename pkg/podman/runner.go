package podman

import (
	"os"
	"os/user"
	"path/filepath"
	"syscall"
)

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

func BuildRunArgs(homeDir, workspaceDir string, cmd []string) []string {
	args := []string{
		"run", "-it", "--rm",
		"--label=app=sklein-devbox",
		"--userns=keep-id",
		"--cap-add=SETUID",
		"--cap-add=SETGID",
		"-e", "TERM",
		"-v", workspaceDir + ":/workspace:U",
		"-v", homeDir + ":/home/sklein:U",
		"sklein-devbox",
	}

	args = append(args, cmd...)
	return args
}

func Run(homeDir, workspaceDir string) error {
	return RunWithCmd(homeDir, workspaceDir, []string{"/bin/zsh"})
}

func RunWithCmd(homeDir, workspaceDir string, cmd []string) error {
	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return err
	}

	args := []string{"podman"}
	args = append(args, BuildRunArgs(homeDir, workspaceDir, cmd)...)

	env := os.Environ()

	err = syscall.Exec(podmanPath, args, env)
	return err
}
