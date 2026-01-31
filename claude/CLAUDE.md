Before executing EVERY prompt - rephrase it for clarity in ENGLISH and print to console. Even if the initial request was in Russian.

## Mental Model Sync (STRICT)

ALWAYS verify user's logic before implementing. When uncertain or when the request suggests architectural misunderstanding:

1. **STOP** - Do NOT assume user's intent
2. **ASK** - Request explicit clarification before proceeding
3. **EXPLAIN** - If you see a potential conflict, describe it clearly

### MUST flag and ask when:

- Request would break existing APIs or contracts
- Request contradicts the codebase architecture
- Request conflicts with earlier session decisions
- You're uncertain about user's intent (even slightly)
- Path, filename, or target location is ambiguous

### Goal:

Reduce uncertainty. Keep user's mental model and Claude's context aligned. When in doubt, ASK - don't guess.
