package podman

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
)

func Run(homeDir, workspaceDir string) error {
	podmanPath, err := exec.LookPath("podman")
	if err != nil {
		return fmt.Errorf("podman not found: %w", err)
	}

	args := []string{
		"podman", "run", "-it", "--rm",
		"--label=app=sklein-devbox",
		"--userns=keep-id",
		"--cap-add=SETUID",
		"--cap-add=SETGID",
		"-e", "TERM",
		"-v", workspaceDir + ":/workspace:U",
		"-v", homeDir + ":/home/sklein:U",
		"sklein-devbox",
	}

	env := os.Environ()

	err = syscall.Exec(podmanPath, args, env)
	return err
}
