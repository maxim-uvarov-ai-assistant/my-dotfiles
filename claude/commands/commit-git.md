---
allowed-tools: Task
description: Create a git commit with smart staging for session work
---

## Your task

Delegate commit creation to the commit-git subagent, passing the list of files modified in the current session.

1. Recall which files were created, edited, or deleted in this session
2. Call the commit-git subagent with the specific file list

Use this format when calling the subagent:
"Use the commit-git subagent to commit these session files: [list of files]"

This ensures the subagent only commits files from our current work session.

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
