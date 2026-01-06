---
allowed-tools: Bash(jj status:*), Bash(jj commit:*), Bash(jj diff:*), Bash(jj describe:*), Bash(jj squash:*), Bash(jj new:*), Bash(jj log:*), Bash(jj file list:*), Bash(jj file track:*), Bash(jj file untrack:*)
description: Create a jj commit
---

## Context

- Current jj status:
!`jj status`

- Current jj diff (working copy changes):
!`jj diff`

- Recent commits:
!`jj log --limit 10`

## Your task

We use jj (Jujutsu) for version control.
Based on the above changes:

- Review the context and understand what changes are present
- **Group changes by purpose**: Create separate commits for unrelated changes
  - Example: docs changes separate from feature changes, tests separate from implementation
  - Use `jj squash <files> -m 'message'` to commit specific files to parent
  - For unrelated changes **within a single file**: ask user to run `/jj-split-file-for-commit <file>`
- If necessary, understand what should be added to .gitignore
- **To untrack files**: First add to .gitignore, then use `jj file untrack <file>` (NOT `jj abandon`)
- Use these AI-safe commands:
  - `jj commit -m 'description'` (commits all current changes)
  - `jj squash <filepaths> -m 'description'` (move specific files to parent)
  - `jj describe -m 'description'` (set description for current working copy)
  - `jj new <base>` (create new working copy commit)

## Important Notes for AI Agents

- **NEVER use interactive commands** like `jj split` without files, `jj squash -i`, or `jj resolve`
- **Always specify `-m` flag** to avoid interactive editor
- **Working copy is automatically committed** - changes are tracked immediately
- **Use file-specific operations** for selective commits: `jj squash <files>`
- **No staging area** - all changes in working copy are included unless specified otherwise

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
