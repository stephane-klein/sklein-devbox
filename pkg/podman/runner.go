package podman

import (
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"syscall"
)

type ContainerOptions struct {
	Gopass           bool
	NoGopassMount    bool
	NoSshMount       bool
	NoMiseCacheMount bool
	NoPulseAudio     bool
	NoPullImage      bool
	SshKeyFile       string
	AgeKeyFile       string
	MiseCacheDir     string
	NetworkHost      bool
	PodmanSocket     bool
	NoWaylandSocket bool
}

func GetHomeDir(instanceName string) (string, error) {
	usr, err := user.Current()
	if err != nil {
		return "", err
	}

	homeDir := filepath.Join(usr.HomeDir, ".local", "share", "sklein-devbox", "instances", instanceName)

	if err := os.MkdirAll(homeDir, 0755); err != nil {
		return "", err
	}

	return homeDir, nil
}

func BuildRunArgs(homeDir, workspaceDir, instanceName string, opts *ContainerOptions, cmd []string) []string {
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

	if opts.Gopass {
		args = append(args, "-e", "SKLEIN_DEVBOX_GOPASS=1")
	}

	if opts.SshKeyFile != "" {
		args = append(args, "-v", opts.SshKeyFile+":/tmp/sklein-devbox-ssh-key:ro")
	}

	if opts.AgeKeyFile != "" {
		args = append(args, "-v", opts.AgeKeyFile+":/tmp/sklein-devbox-age-key:ro")
	}

	if _, err := os.Stat(filepath.Join(home, ".ssh")); err == nil && !opts.NoSshMount {
		args = append(args, "-v", filepath.Join(home, ".ssh")+":/home/sklein/.ssh:U")
	}

	hasGopass := false
	if _, err := os.Stat(filepath.Join(home, ".config", "gopass")); err == nil {
		hasGopass = true
	}
	if _, err := os.Stat(filepath.Join(home, ".local", "share", "gopass")); err == nil {
		hasGopass = true
	}

	if hasGopass && !opts.NoGopassMount {
		args = append(args, "-v", filepath.Join(home, ".config", "gopass", "age", "identities")+":/home/sklein/.config/gopass/age/identities:U")
		args = append(args, "-v", filepath.Join(home, ".local", "share", "gopass")+":/home/sklein/.local/share/gopass:U")
	}

	if !opts.NoMiseCacheMount {
		miseCacheDir := opts.MiseCacheDir
		if miseCacheDir == "" {
			miseCacheDir = filepath.Join(home, ".local", "share", "mise", "installs")
		}
		os.MkdirAll(miseCacheDir, 0755)
		args = append(args, "-v", miseCacheDir+":/home/sklein/.local/share/mise/installs/:U")
	}

	// Mount PulseAudio socket if available and not disabled
	if !opts.NoPulseAudio {
		runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
		if runtimeDir == "" {
			runtimeDir = filepath.Join("/run", "user", fmt.Sprintf("%d", os.Getuid()))
		}
		pulseSocketPath := filepath.Join(runtimeDir, "pulse", "native")
		if _, err := os.Stat(pulseSocketPath); err == nil {
			args = append(args, "-v", pulseSocketPath+":/tmp/pulse-remote.sock")
		}
	}

	// Mount Wayland socket if available on host and not disabled
	if !opts.NoWaylandSocket {
		runtimeDir := os.Getenv("XDG_RUNTIME_DIR")
		if runtimeDir == "" {
			runtimeDir = filepath.Join("/run", "user", fmt.Sprintf("%d", os.Getuid()))
		}
		waylandDisplay := os.Getenv("WAYLAND_DISPLAY")
		if waylandDisplay == "" {
			waylandDisplay = "wayland-0"
		}
		waylandSocketPath := filepath.Join(runtimeDir, waylandDisplay)
		if _, err := os.Stat(waylandSocketPath); err == nil {
			args = append(args, "-v", waylandSocketPath+":/tmp/wayland-0")
		}
	}

	if opts.NetworkHost {
		args = append(args, "--network=host")
	}

	if opts.PodmanSocket {
		uid := os.Getuid()
		hostSocketPath := filepath.Join("/run", "user", fmt.Sprintf("%d", uid), "podman", "podman.sock")
		args = append(args, "-v", hostSocketPath+":/run/user/1000/podman/podman.sock")
		args = append(args, "-e", "XDG_RUNTIME_DIR=/run/user/1000")
		args = append(args, "-e", "CONTAINER_HOST=unix:///run/user/1000/podman/podman.sock")
	}

	args = append(args, "ghcr.io/stephane-klein/sklein-devbox:latest")

	args = append(args, cmd...)
	return args
}

func Run(homeDir, workspaceDir, instanceName string, opts *ContainerOptions) error {
	return RunWithCmd(homeDir, workspaceDir, instanceName, opts, []string{})
}

func RunWithCmd(homeDir, workspaceDir, instanceName string, opts *ContainerOptions, cmd []string) error {
	if err := os.MkdirAll(homeDir, 0755); err != nil {
		return err
	}

	if opts.Gopass && !opts.NoGopassMount {
		gopassDirs := []string{
			filepath.Join(homeDir, ".config", "gopass", "age"),
			filepath.Join(homeDir, ".local", "share", "gopass"),
		}
		for _, dir := range gopassDirs {
			if err := os.MkdirAll(dir, 0755); err != nil {
				return err
			}
		}
	}

	// Ensure mise parent directory exists in instance home so Podman
	// chowns it correctly via the :U flag on the home mount
	miseParentDir := filepath.Join(homeDir, ".local", "share", "mise")
	if err := os.MkdirAll(miseParentDir, 0755); err != nil {
		return err
	}

	if opts.PodmanSocket {
		if err := EnsurePodmanSocket(); err != nil {
			return err
		}
	}

	podmanPath, err := GetPodmanBinPath()
	if err != nil {
		return err
	}

	args := []string{"podman"}
	args = append(args, BuildRunArgs(homeDir, workspaceDir, instanceName, opts, cmd)...)

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
