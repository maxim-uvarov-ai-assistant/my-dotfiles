# Nutest Quick Reference Card

## Setup & Import
```nushell
use /path/to/nutest
```

## Test File Naming
- `test_*.nu` `test-*.nu` `*_test.nu` `*-test.nu`

## Annotations
| Annotation | Usage |
|------------|-------|
| `@test` | `@test`<br>`def "test name" [] { ... }` |
| `@before-all` | Run once before all tests |
| `@before-each` | Run before each test, passes context via `$in` |
| `@after-all` | Run once after all tests |
| `@after-each` | Run after each test |
| `@ignore` | Skip test |
| `@strategy: serial` | Force sequential execution |

## Basic Commands
```nushell
# Run all tests
nutest run-tests

# Run with options
nutest run-tests --path ./tests --match-tests "api.*" --fail

# List tests
nutest list-tests
```

## Context Pattern
```nushell
@before-each
def setup [] {
    { temp_dir: (mktemp -d), data: "test" }
}

@test
def "my test" [] {
    let ctx = $in  # Context from setup
    # Use $ctx.temp_dir, $ctx.data
}
```

## Common Test Patterns
```nushell
# Basic assertion
@test
def "should work" [] {
    assert equal (2 + 2) 4
}

# External command
@test
def "external cmd" [] {
    let result = ^echo "test" | complete
    assert equal $result.exit_code 0
}

# Error testing
@test
def "should fail" [] {
    let error = try { bad-command } catch { |e| $e.msg }
    assert str contains $error "expected error"
}
```

## Key Flags
| Flag | Purpose |
|------|---------|
| `--fail` | Exit non-zero on failure (CI) |
| `--match-tests <pattern>` | Filter tests |
| `--match-suites <pattern>` | Filter suites |
| `--display terminal` | Real-time output |
| `--display table` | Summary table |
| `--returns summary` | Return stats |
| `--report {type: junit, path: "file.xml"}` | Generate report |
| `--threads N` | Parallel threads |

## CI Integration
```yaml
# GitHub Actions
- run: nu -c "use nutest; nutest run-tests --fail --report {type: junit, path: results.xml}"
```

## Common Mistakes
- ❌ Missing `@test` annotation
- ❌ `let ctx = setup` (should be `let ctx = $in`)
- ❌ Tests depend on each other
- ❌ No cleanup in `@after-each`

## Best Practices
- One assertion per test
- Descriptive test names
- Use temp directories for file tests
- Clean up in `@after-each`
- Test both success and error cases