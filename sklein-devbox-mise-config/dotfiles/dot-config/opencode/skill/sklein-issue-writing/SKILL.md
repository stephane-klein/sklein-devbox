---
name: sklein-issue-writing
description: "Conventions for writing issues — todo section formatting rules by sklein"
---

# sklein-issue-writing

Issue writing conventions.

## Language

Issues must be written in **English** by default, unless explicitly specified otherwise by the human.

## Todo (Implementation Plan)

The implementation plan section must be titled `### Todo (Implementation Plan)` and written as a markdown checklist with one or more levels.

Every actionable step must be a checkbox (`- [ ]`), never plain text.

Do not insert blank lines between checklist items or nested items. The list must be continuous without extra vertical spacing.

Example:

```markdown
### Todo (Implementation Plan)

- [ ] **CLI changes** (`pkg/podman/container.go`):
  - [ ] Add `--no-wayland` flag (default: false) to disable Wayland socket mount
  - [ ] Add Wayland socket mount in `buildContainerArgs()` when available on host
  - [ ] Add `WAYLAND_DISPLAY=wayland-0` environment variable
- [ ] **Container image** (in `sklein-devbox-chezmoi` repo):
  - [ ] Add `wl-clipboard` package to Containerfile
```
