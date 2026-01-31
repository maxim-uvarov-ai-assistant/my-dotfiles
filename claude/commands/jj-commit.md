---
allowed-tools: Bash(jj status:*), Bash(jj commit:*), Bash(jj diff:*), Bash(jj describe:*), Bash(jj squash:*), Bash(jj new:*), Bash(jj log:*), Bash(jj file list:*), Bash(jj file track:*), Bash(jj file untrack:*), Bash(jj metaedit:*)
description: Create a jj commit
---

## Context

- Current jj status:
!`jj status`

- Current jj diff (working copy changes):
!`jj diff --git`

- Recent commits:
!`jj log --limit 10`

## Your task

We use jj (Jujutsu) for version control.
Based on the above changes:

- **Default scope: session files only** - Unless explicitly asked to commit all changes, only commit files you modified during this session
  - **How to identify session files**: Review your conversation history for Read, Edit, Write tool calls - these are your session files
  - Cross-reference `jj status` with files you edited/created in this conversation
  - Files in `jj status` that you never touched = pre-existing changes, skip them
- Review the context and understand what changes are present
- **Group changes by purpose**: Create separate commits for unrelated changes
  - Example: docs changes separate from feature changes, tests separate from implementation
  - Use `jj commit <files> -m 'message'` to commit specific files
  - **Never squash commits unless explicitly asked** - use `jj commit`, not `jj squash`
  - For unrelated changes **within a single file**: ask user to run `/jj-split-file-for-commit <file>`
- If necessary, understand what should be added to .gitignore
- **To untrack files**: First add to .gitignore, then use `jj file untrack <file>` (NOT `jj abandon`)
- Use these AI-safe commands:
  - `jj commit -m 'description' && jj metaedit @- --update-author` (commits all current changes)
  - `jj commit <files> -m 'description' && jj metaedit @- --update-author` (commit specific files only)
  - `jj describe -m 'description'` (set description for current working copy)
  - `jj new <base>` (create new working copy commit)
  - `jj squash <filepaths> -m 'description'` (only when user explicitly asks)
  - `jj log -n 5` (show last 5 commits - use `-n` flag, NOT revset ranges)
- **Always run `jj metaedit @- --update-author` after commit** - see "Author Attribution" below

## Author Attribution

In jj, the working copy is always a commit. When the user works in their shell, jj creates/updates the working copy with **their** identity. By the time Claude runs `jj commit`, the author is already set to the user.

**Solution:** After committing, run `jj metaedit @- --update-author` to update the author to the configured user (from `JJ_CONFIG` env var pointing to claude's config).

```bash
# Pattern: commit, then fix author on the just-committed change (@-)
jj commit <files> -m 'message' && jj metaedit @- --update-author
```

Why this approach:
- Author is managed in config (`~/.config/jj/jj-config-claude-ai.toml`), not hardcoded in commands
- `--update-author` reads from `user.name`/`user.email` in config
- Avoids deprecated `jj commit --author` flag

## Important Notes for AI Agents

- **Always run `&& jj metaedit @- --update-author`** after `jj commit` - unless user explicitly asks otherwise
- **Commit exact files by default** - always use `jj commit <specific-files> -m 'message'` to commit only the intended files
- **NEVER use interactive commands** like `jj split` without files, `jj squash -i`, or `jj resolve`
- **Always specify `-m` flag** to avoid interactive editor
- **Working copy is automatically committed** - changes are tracked immediately
- **Use file-specific operations** for selective commits: `jj commit <files>` (not `jj squash` unless asked)
- **No staging area** - all changes in working copy are included unless specified otherwise
- **Revset range order**: `older::newer` (e.g., `@---::@`), NOT `newer::older` - wrong order = empty result

## Commit message conventions

Use conventional commits format: `<type>: <description>`

| Type | Changelog Category | Use for |
|------|-------------------|---------|
| `feat:` | Added | New features |
| `change:` | Changed | Existing functionality changes |
| `fix:` | Fixed | Bug fixes |
| `remove:` | Removed | Removed features |
| `security:` | Security | Vulnerability fixes |
| `deprecate:` | Deprecated | Soon-to-be removed |
| `refactor:` | - | Code changes without behavior change |
| `docs:` | - | Documentation only |
| `test:` | - | Test changes |
| `chore:` | - | Maintenance tasks |
| `init:` | - | Initialization |

Breaking changes: add '!' after type (e.g., `feat!: change API format`)
