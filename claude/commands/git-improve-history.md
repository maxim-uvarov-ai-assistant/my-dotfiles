---
allowed-tools: Bash(git:*), Read, Write, Edit
description: Improve git commit messages using patches to preserve original authorship
argument-hint: [branch-name]
---

# Improve Git History with Patches

Improve commit messages while preserving original authorship using git format-patch workflow. Automatically handles all unpublished commits.

⚠️ **WARNING**: Only edits commits that have NOT been pushed to a shared repository. Rewriting published history will cause conflicts for other developers.

## Arguments

- `branch-name` (optional): Base branch to compare against (default: master)

## Context

### Parse Arguments
```bash
BASE_BRANCH="${ARGUMENTS:-master}"
```

### Repository Status

- Git repository: !`git rev-parse --is-inside-work-tree 2>/dev/null && echo "Yes" || echo "No"`
- Current branch: !`git branch --show-current`
- Base branch: !`echo ${BASE_BRANCH:-master}`
- Working directory: !`test -z "$(git status --porcelain 2>/dev/null)" && echo "Clean" || echo "Has uncommitted changes"`
- Unpublished commits: !`git rev-list ${BASE_BRANCH:-master}..HEAD --count 2>/dev/null || echo "0"`
- Recent unpublished commits: !`git log --oneline ${BASE_BRANCH:-master}..HEAD 2>/dev/null || echo "No unpublished commits"`

## Task

### 1. Update Base Branch and Check Rebase Status

First, ensure the base branch is up-to-date and current branch is rebased:

```bash
# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo "Error: Working directory has uncommitted changes. Please commit or stash them first."
    exit 1
fi

# Store current branch name
CURRENT_BRANCH=$(git branch --show-current)

# Determine the remote name (usually origin)
REMOTE=$(git config --get branch.${BASE_BRANCH}.remote || echo "origin")

# Check if remote exists
if ! git remote | grep -q "^${REMOTE}$"; then
    echo "Error: Remote '${REMOTE}' does not exist."
    exit 1
fi

# Fetch latest changes from remote
echo "Fetching latest changes from ${REMOTE}..."
git fetch ${REMOTE}

# Check if base branch exists locally
if ! git show-ref --verify --quiet refs/heads/${BASE_BRANCH}; then
    echo "Error: Base branch '${BASE_BRANCH}' does not exist locally."
    echo "You may need to checkout ${BASE_BRANCH} first: git checkout ${BASE_BRANCH}"
    exit 1
fi

# Check if we're on the base branch
if [ "$CURRENT_BRANCH" = "${BASE_BRANCH}" ]; then
    echo "Error: You are currently on the base branch '${BASE_BRANCH}'."
    echo "Please switch to a feature branch before running this command."
    exit 1
fi

# Update base branch to match remote (safe because we're not on it)
echo "Updating ${BASE_BRANCH} from ${REMOTE}..."
REMOTE_REF="${REMOTE}/${BASE_BRANCH}"
if git show-ref --verify --quiet refs/remotes/${REMOTE_REF}; then
    git fetch ${REMOTE} ${BASE_BRANCH}:${BASE_BRANCH}
else
    echo "Warning: Remote branch ${REMOTE_REF} not found. Using local ${BASE_BRANCH}."
fi

# Check if current branch needs rebasing
MERGE_BASE=$(git merge-base HEAD ${BASE_BRANCH})
BASE_TIP=$(git rev-parse ${BASE_BRANCH})

if [ "$MERGE_BASE" != "$BASE_TIP" ]; then
    echo "⚠️  ERROR: Current branch is not rebased on latest ${BASE_BRANCH}"
    echo "Merge base: $MERGE_BASE"
    echo "${BASE_BRANCH} tip: $BASE_TIP"
    echo ""
    echo "Please rebase your branch first:"
    echo "  git rebase ${BASE_BRANCH}"
    echo ""
    echo "Then run this command again."
    exit 1
fi

# Count unpublished commits
COMMIT_COUNT=$(git rev-list ${BASE_BRANCH}..HEAD --count)

if [ "$COMMIT_COUNT" -eq 0 ]; then
    echo "No unpublished commits found between ${BASE_BRANCH} and HEAD."
    exit 0
fi

echo "Found ${COMMIT_COUNT} unpublished commits to improve."

# Create backup branch
BACKUP_BRANCH="${CURRENT_BRANCH}_backup_$(date +%Y%m%d_%H%M%S)"
git branch "$BACKUP_BRANCH"
echo "Created backup branch: $BACKUP_BRANCH"

# Create patches directory
PATCH_DIR="/tmp/git-patches-$$"
mkdir -p "$PATCH_DIR"

# Generate patches for all unpublished commits
git format-patch ${BASE_BRANCH}..HEAD -o "$PATCH_DIR" --numbered
echo "Generated ${COMMIT_COUNT} patches in: $PATCH_DIR"
```

### 2. Analyze Current Commit Messages

Review the current commit messages and identify improvements needed:

```bash
echo "=== Current Commit Messages ==="
git log --format="Commit %h by %an <%ae>%n  Date: %ad%n  Subject: %s%n  Body: %b%n" ${BASE_BRANCH}..HEAD
```

Common issues to look for:
- Vague messages like "version", "fix", "update", "changes"
- Missing context about WHY changes were made
- Grammar or spelling errors
- Not following conventional commit format
- Missing issue/ticket references
- Overly long subject lines (>72 chars)

### 3. Edit Patch Files to Improve Messages

For each patch file in `$PATCH_DIR`, edit the commit message while preserving authorship:

```bash
# List all patches
ls -la "$PATCH_DIR"/*.patch
```

Each patch file contains:
- `From:` line with author info (DO NOT MODIFY)
- `Date:` line with original timestamp (DO NOT MODIFY)
- `Subject:` line with commit message (EDIT THIS)
- Message body section (EDIT THIS)

Example patch structure:
```
From abc123... Mon Sep 17 00:00:00 2001
From: Original Author <author@email.com>  # PRESERVE THIS
Date: Mon, 1 Jan 2024 12:00:00 +0000      # PRESERVE THIS
Subject: [PATCH 1/5] fix: correct API endpoint validation  # IMPROVE THIS

Add proper validation for API endpoints to prevent     # IMPROVE THIS
security issues when handling user input.

Fixes #123
```

### 4. Review and Edit Each Patch

Now edit each patch file to improve commit messages:

```bash
# Show patches that need editing
for patch in "$PATCH_DIR"/*.patch; do
    echo "=== $(basename $patch) ==="
    grep -A5 "^Subject:" "$patch"
done
```

Edit the patches to improve messages while keeping authorship intact.

```bash
# Stop here to let Claude edit the patches
echo ""
echo "=== Patches generated successfully ==="
echo "Location: $PATCH_DIR"
echo "Count: ${COMMIT_COUNT} patches"
echo ""
echo "Now Claude will edit these patches to improve commit messages."
```

### 5. Apply Improved Patches

After editing all patch files, reset the branch and apply the improved patches:

```bash
# Reset to the base branch (this is safe, we have backup)
echo "Resetting to ${BASE_BRANCH}..."
git reset --hard ${BASE_BRANCH}

# Apply the edited patches
echo "Applying edited patches..."
git am "$PATCH_DIR"/*.patch || {
    echo "⚠️  Error: Failed to apply patches."
    echo "To recover: git am --abort && git reset --hard $BACKUP_BRANCH"
    exit 1
}

echo "✅ Successfully applied improved commits with preserved authorship!"
```

### 6. Verify Authorship Preservation

Confirm that original authorship is preserved:

```bash
echo "=== Updated Commits with Preserved Authorship ==="
git log --format="Commit %h%nAuthor: %an <%ae> (preserved)%nCommitter: %cn <%ce> (updated)%nDate: %ad%nSubject: %s%n" ${BASE_BRANCH}..HEAD
```

### 7. Cleanup and Recovery Instructions

```bash
echo "=== Cleanup ==="
echo "Patch directory: $PATCH_DIR"
echo "To remove patches: rm -rf $PATCH_DIR"
echo ""
echo "=== Recovery ==="
echo "If something went wrong, restore from backup:"
echo "  git reset --hard $BACKUP_BRANCH"
echo ""
echo "To delete backup branch after verification:"
echo "  git branch -D $BACKUP_BRANCH"
```

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
