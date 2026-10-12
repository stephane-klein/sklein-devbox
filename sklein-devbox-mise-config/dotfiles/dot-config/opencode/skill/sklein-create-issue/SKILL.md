---
name: create-issue
description: "Create GitHub issues. Use gh-issue-sync new, then view to verify, then Edit the file at $GH_ISSUE_SYNC_DIR. NEVER explore the project, NEVER Read issue files, NEVER use --edit, NEVER launch explore/task agents, NEVER push."
---

# create-issue

Always use this skill when user asks to create GitHub issues.

## MANDATORY RULES — READ FIRST

1. DO NOT explore the project, read project files, or launch explore/task agents. Use ONLY the information provided by the user in their request.
2. DO NOT verify that gh-issue-sync is installed or initialized.
3. DO NOT Read created issue files. Use `gh-issue-sync view <T-ID>` to verify, then Edit the file directly.
4. DO NOT run `gh-issue-sync pull`, `list`, `status`, `diff`, or `init` before creating.
5. DO NOT manually create `.issues/` files — always use `gh-issue-sync new`.
6. NEVER use `--edit` flag (opens interactive editor, will hang).
7. DO NOT glob, read, or explore `.issues/` directory.
8. DO NOT run `gh-issue-sync push` — the user will push manually when ready.
9. If a command fails, report the error and STOP.

## Environment

The `GH_ISSUE_SYNC_DIR` environment variable is set to the absolute path of the `.issues/` directory. When editing issue files, use the path `$GH_ISSUE_SYNC_DIR/open/<T-ID>-<slug>.md`.

## Workflow

1. **Load gh-issue-sync skill**: Use `skill gh-issue-sync` tool to load it first
2. **Run `gh-issue-sync new "Title" --label enhancement`** → note the T-ID and file name from output
3. **Run `gh-issue-sync view <T-ID>`** to verify creation
4. **Edit the file** at `$GH_ISSUE_SYNC_DIR/open/<T-ID>-<slug>.md` (use Edit tool directly, NOT Read) to add the body and todo checklist (follow sklein-issue-writing conventions)

## Never

- Use `gh issue create` directly
- Explore project files or structure before or after creating an issue
- Run `gh-issue-sync push` — the user will push when ready
- Present your workflow steps to the user. Just execute directly and show the result