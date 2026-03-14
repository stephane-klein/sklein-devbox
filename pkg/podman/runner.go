package podman

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
)

func Run(homeDir, workspaceDir, entrypointPath, chezmoiSourceDir string) error {
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
		"-v", workspaceDir + ":/workspace",
		"-v", homeDir + ":/home/sklein",
		"-v", entrypointPath + ":/usr/local/bin/entrypoint.sh",
		"-e", "CHEZMOI_SOURCE_DIR=/workspace/chezmoi",
		"sklein-devbox",
	}

	env := os.Environ()

	err = syscall.Exec(podmanPath, args, env)
	return err
}
