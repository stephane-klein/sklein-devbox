---
name: gh-issue-sync
description: "Create and edit GitHub issues via gh-issue-sync CLI. NEVER push, NEVER verify setup, NEVER pull/list/status before acting, NEVER use --edit, NEVER manually create .issues/ files, NEVER launch explore/task agents, NEVER Read issue files. Use gh-issue-sync view to verify, then Edit."
---

# gh-issue-sync

## MANDATORY RULES — READ FIRST

1. DO NOT verify that gh-issue-sync is installed, initialized, or working. Just run the command.
2. DO NOT run `gh-issue-sync push`. The user will push manually when ready.
3. DO NOT run `gh-issue-sync pull`, `list`, `status`, `diff`, or `init` before acting. Just run the command needed for the task.
4. DO NOT glob, read, or explore `.issues/` directory. DO NOT launch explore or task agents before or after creating an issue.
5. DO NOT manually create `.issues/` files. Always use `gh-issue-sync new`.
6. NEVER use `--edit` flag. It opens an interactive editor and will hang forever.
7. NEVER Read created issue files with the Read tool. Use `gh-issue-sync view <T-ID>` to verify content, then Edit the file directly.
8. If a command fails or a created file is not found, report the error and STOP. Do NOT search for the file with find, glob, or ls — just report the error.
9. In plan mode, do NOT execute gh-issue-sync commands. Present the planned commands and wait for execution mode.
10. Do NOT present your workflow steps to the user. Just execute the commands directly.

## Environment

The `GH_ISSUE_SYNC_DIR` environment variable is set to the absolute path of the `.issues/` directory (e.g. `/workspace/sklein-devbox/.issues`). All `gh-issue-sync` commands use it automatically. When editing issue files with the Edit tool, use the path `$GH_ISSUE_SYNC_DIR/open/<T-ID>-<slug>.md`.

## Commands

```
gh-issue-sync new "Title"           # Create issue (--label, WITHOUT --edit)
gh-issue-sync view T1a2b3c         # View issue content (use to verify creation)
gh-issue-sync close 42              # Close (--reason completed|not_planned)
gh-issue-sync reopen 42
```

NOTE: `gh-issue-sync push` is intentionally omitted. The user will push manually when ready.

## Workflow: Create an issue

1. Run `gh-issue-sync new "Title" --label enhancement` → note the T-ID and file name from the output (e.g. `T1a2b3c`, `T1a2b3c-slug.md`)
2. Run `gh-issue-sync view <T-ID>` to verify creation
3. Edit the file at `$GH_ISSUE_SYNC_DIR/open/<T-ID>-<slug>.md` with the Edit tool to add issue body and todo checklist. Do NOT Read the file first — just Edit it directly.

## Workflow: Close/reopen an issue

1. `gh-issue-sync close 42` or `gh-issue-sync reopen 42`