---
allowed-tools: Bash(jj:*), Read, Edit
description: Improve jj commit messages while preserving original authorship
argument-hint: [base-revision]
---

# Improve Jujutsu History

Improve commit messages while automatically preserving original authorship. Unlike git, jj's `describe` command preserves the original author - no patch workflow needed!

## Arguments

- `base-revision` (optional): Base revision to compare against (default: main)

## Context

### Parse Arguments
```bash
BASE_REV="${ARGUMENTS:-main}"
```

### Repository Status

- jj repository: !`jj workspace root 2>/dev/null && echo "Yes" || echo "No"`
- Current revision: !`jj log -r @ --no-graph --template 'change_id.short() ++ " " ++ description.first_line()' 2>/dev/null`
- Base revision: `$ARGUMENTS` (default: main)
- Working copy clean: !`jj diff --stat 2>/dev/null | grep -q . && echo "Has changes" || echo "Clean"`

## Task

### 1. Verify Repository State

```bash
# Check we're in a jj repo
if ! jj workspace root >/dev/null 2>&1; then
    echo "Error: Not in a jj repository"
    exit 1
fi

# Check for uncommitted changes in working copy
if jj diff --stat 2>/dev/null | grep -q .; then
    echo "Warning: Working copy has uncommitted changes"
    echo "These will be preserved but consider committing first"
fi

# Get list of commits to improve
COMMITS=$(jj log -r "${BASE_REV}..@-" --no-graph --template 'change_id ++ "\n"' 2>/dev/null)
COMMIT_COUNT=$(echo "$COMMITS" | grep -c . || echo 0)

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "No unpublished commits found between ${BASE_REV} and @-"
    exit 0
fi

echo "Found ${COMMIT_COUNT} commits to review for message improvements"
```

### 2. Analyze Current Commit Messages

Review the current commit messages and identify improvements needed:

```bash
echo "=== Current Commit Messages ==="
jj log -r "${BASE_REV}..@-" --template '
change_id.short() ++ " by " ++ author.name() ++ " <" ++ author.email() ++ ">\n" ++
"  Date: " ++ author_date ++ "\n" ++
"  Subject: " ++ description.first_line() ++ "\n" ++
if(description.rest(), "  Body: " ++ description.rest() ++ "\n", "") ++
"\n"
'
```

Common issues to look for:
- Vague messages like "version", "fix", "update", "changes"
- Missing context about WHY changes were made
- Grammar or spelling errors
- Not following conventional commit format
- Missing issue/ticket references
- Overly long subject lines (>72 chars)

### 3. Improve Each Commit Message

For each commit that needs improvement, use `jj describe`:

```bash
# List commits with change IDs for easy reference
echo "=== Commits to Improve ==="
jj log -r "${BASE_REV}..@-" --no-graph --template '
"Change ID: " ++ change_id.short() ++ "\n" ++
"Author: " ++ author.name() ++ " <" ++ author.email() ++ "> (will be preserved)\n" ++
"Current message: " ++ description.first_line() ++ "\n" ++
"---\n"
'
```

To improve a commit message (authorship is automatically preserved):

```bash
# Example - improve a specific commit
jj describe <change_id> -m "$(cat <<'EOF'
feat: add user authentication flow

Implement OAuth2 authentication with support for Google and GitHub
providers. This enables single sign-on for enterprise customers.

- Add OAuth2 client configuration
- Implement token refresh logic
- Add user session management

Closes #123
EOF
)"
```

### 4. Verify Authorship Preservation

Confirm that original authorship is preserved after improvements:

```bash
echo "=== Updated Commits with Preserved Authorship ==="
jj log -r "${BASE_REV}..@-" --template '
change_id.short() ++ "\n" ++
"  Author: " ++ author.name() ++ " <" ++ author.email() ++ "> (preserved)\n" ++
"  Committer: " ++ committer.name() ++ " <" ++ committer.email() ++ "> (updated)\n" ++
"  Message: " ++ description.first_line() ++ "\n\n"
'
```

### 5. Recovery Instructions

```bash
echo "=== Recovery ==="
echo "If something went wrong, use jj's operation log:"
echo "  jj op log                    # View recent operations"
echo "  jj undo                      # Undo last operation"
echo "  jj op restore <operation_id> # Restore to specific point"
```

## Key Advantage Over Git

In git, improving commit messages while preserving authorship requires a complex `format-patch` workflow:
1. Generate patches with `git format-patch`
2. Edit patch files manually (preserving From: and Date: headers)
3. Reset branch and apply with `git am`

In jj, it's a single command:
```bash
jj describe <change_id> -m "improved message"
```

The original author is automatically preserved. Only the committer info is updated.

## Best Practices for Commit Messages

When improving messages, follow these guidelines:

1. **Subject line** (first line):
   - Use imperative mood ("Add feature" not "Added feature")
   - Limit to 50-72 characters
   - Capitalize first letter
   - No period at the end
   - Include type prefix if using conventional commits (feat:, fix:, docs:, etc.)

2. **Body** (after blank line):
   - Explain WHY the change was made
   - Wrap at 72 characters
   - Include relevant context
   - Reference issues/tickets

3. **Example improvement**:
   ```
   Before: "update code"
   After:  "fix: validate user input in authentication flow

   Prevent SQL injection by properly escaping user-provided
   credentials before database queries. This addresses the
   security audit finding from last week.

   Fixes #SEC-2024-001"
   ```
