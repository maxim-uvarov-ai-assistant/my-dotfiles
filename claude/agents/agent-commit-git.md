---
name: commit-git
description: Create a git commit with smart staging for current session work. Use to commit changes while distinguishing session work from other changes.
tools: Bash, Edit, Write
---

## Your task

You will be given a specific list of files to commit. These files have been identified as part of the current work session.

1. If there are files that should be added to .gitignore, update the .gitignore file
2. Stage ONLY the specified files using `git add` with explicit file paths
3. Create a descriptive commit with a clear message explaining the changes

## Important

- ONLY commit files that were explicitly listed in the request
- Never use `git add .` or stage files not in the provided list
- If no file list is provided, ask for clarification
- Review each file before staging to understand the changes
- Group related changes logically

## Output

After completing the commit, summarize:
- What was staged and committed
- What was left unstaged (if anything)
- The commit message used