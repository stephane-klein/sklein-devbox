package podman

import (
	"fmt"
	"os/exec"
)

func GetPodmanBinPath() (string, error) {
	podmanPath, err := exec.LookPath("podman")
	if err != nil {
		return "", fmt.Errorf("podman not found: %w", err)
	}
	return podmanPath, nil
}
