---
allowed-tools: Read, Write, Edit, MultiEdit, Bash, Grep, Glob, TodoWrite
description: Process and improve markdown task files with implementation planning
argument-hint: <task-file.md>
---

# Process Markdown Task File

Process task files: improve quality, create implementation plan, prepare for execution.

## Quick Start

!`[ -f "$ARGUMENTS" ] && echo "✓ File exists: $ARGUMENTS" || echo "✗ File not found: $ARGUMENTS"`

## Main Process

### 0. Auto-rename if needed
Check format and rename `YYYYMMDD-N.md` → `YYYYMMDD-N-short-name.md`:
```bash
FILENAME=$(basename "$ARGUMENTS")
if [[ "$FILENAME" =~ ^([0-9]{4}[0-9]{2}[0-9]{2}-[0-9]+)\.md$ ]]; then
    PREFIX="${BASH_REMATCH[1]}"
    TITLE=$(head -10 "$ARGUMENTS" | grep -m1 "^#" | sed 's/^#*\s*//' || head -1 "$ARGUMENTS")
    SHORT=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | cut -d'-' -f1-5)
    if [ -n "$SHORT" ]; then
        NEW="$PREFIX-$SHORT.md"
        mv "$ARGUMENTS" "$(dirname "$ARGUMENTS")/$NEW"
        ARGUMENTS="$(dirname "$ARGUMENTS")/$NEW"
        git add -A && git commit -m "rename: $FILENAME → $NEW"
    fi
fi
```

### 1. Read & Analyze
Read @$ARGUMENTS and analyze structure, requirements, and task sequence.

### 2. Improve Quality
- Fix typos and grammar
- Clarify ambiguous statements
- Add questions for unclear points
- Verify logical flow

### 3. Research Context
Use Glob/Grep to understand:
- Code structure and patterns
- Dependencies and constraints

### 4. Add Implementation Plan
```markdown
## Implementation Plan

### Stage 1: [Name]
- [ ] Action 1
- [ ] Action 2
- Expected result: ...
- Files: ...

### Final Check
- [ ] Test functionality
- [ ] Verify requirements
- [ ] Document changes

### Technical Details
- Files: [list]
- Dependencies: [if any]
- Risks: [potential issues]
```

### 5. Handle Existing Plans
For files with existing plans:
- Check history: !`[ -n "$ARGUMENTS" ] && git log --oneline -5 -- "$ARGUMENTS" || echo "No file specified"`
- Update plan for new requirements
- Mark completed items

### 6. Create TODO List
Use TodoWrite to create tasks from plan with proper statuses.

### 7. Commit Changes
```bash
git add "$ARGUMENTS"
git commit -m "feat: Add implementation plan for $(basename "$ARGUMENTS" .md)"
```

## Output
Provide:
1. Summary of changes
2. Implementation plan
3. TODO list
4. Next steps
