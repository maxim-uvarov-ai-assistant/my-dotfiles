# Dotfiles synchronization toolkit
#
# Manages syncing configuration files between this Git repository and the local machine.
# Uses two CSV files for configuration:
#   - paths-default.csv: Single column (full-path) with glob patterns. Repo paths are derived:
#     ~/.config/X/... → X/...  |  ~/.X/... → X/...
#   - paths-local.csv: Optional local overrides with status column (update, ignore)
#
# Commands:
#   pull-from-machine        - Copy configs from machine into repo
#   push-to-machine          - Copy configs from repo to machine
#   preview-push-to-machine  - Show diff of what push would change
#   fill-candidates          - Find new config files to potentially track
#   cleanup-paths-not-in-csv - List repo files not tracked in CSV
#   migrate-csv              - Convert old two-column CSV to new single-column format

export def main [] { }

# Check if a file has uncommitted changes in its git repository
def has-uncommitted-changes [path: path] {
    if not ($path | path exists) { return false }

    let dir = if ($path | path type) == 'dir' { $path } else { $path | path dirname }

    # Check if inside a git repo
    let git_check = do { cd $dir; ^git rev-parse --git-dir } | complete
    if $git_check.exit_code != 0 { return false }

    # Check for uncommitted changes (staged or unstaged)
    let status = do { cd $dir; ^git status --porcelain -- $path } | complete
    ($status.stdout | str trim | is-not-empty)
}

# Check paths for uncommitted changes, print error if found. Returns true if dirty.
def check-dirty-files [paths: table, field: string, context: string] {
    let dirty = $paths | where { has-uncommitted-changes ($in | get $field) }
    if ($dirty | is-not-empty) {
        print $"(ansi red)Error: The following ($context) have uncommitted changes:(ansi reset)"
        $dirty | get $field | each { print $"  ($in)" }
        print $"\nCommit or stash changes first, or use --force to overwrite."
        true
    } else {
        false
    }
}

# Derive repo path from full machine path using convention:
#   ~/.config/X/... → X/...
#   ~/.X/...        → X/...
def derive-repo-path [fullpath: string] {
    let expanded = $fullpath | path expand --no-symlink
    let home = $nu.home-dir
    let config_prefix = $home | path join '.config'

    if ($expanded | str starts-with $config_prefix) {
        $expanded | str replace $"($config_prefix)/" ''
    } else if ($expanded | str starts-with $"($home)/.") {
        $expanded | str replace $"($home)/." ''
    } else {
        $expanded | str replace $"($home)/" ''
    }
}

# Extract static prefix from glob pattern (everything before first glob char)
def glob-base [pattern: string] {
    $pattern | str replace -r '[\*\?\[\{].*$' ''
}

# Read paths-default.csv, expand globs, and derive repo paths
def open-configs [] {
    open paths-default.csv
    | get full-path
    | each {|pattern|
        let expanded = $pattern | path expand --no-symlink
        if ($pattern !~ '[\*\?\[\{]') {
            return [{full-path: $expanded path-in-repo: (derive-repo-path $expanded)}]
        }

        let repo_pattern = derive-repo-path $expanded
        let machine_base = glob-base $expanded
        let repo_base = glob-base $repo_pattern

        # Glob from machine (for pull) and repo (for push when machine dir missing)
        let from_machine = glob $expanded --no-dir
        | each {|f| {full-path: $f path-in-repo: (derive-repo-path $f)} }

        let from_repo = glob $repo_pattern --no-dir
        | each {|f|
            let repo_path = $f | path relative-to (pwd)
            let rel = $repo_path | path relative-to $repo_base
            {path-in-repo: $repo_path full-path: ($machine_base | path join $rel)}
        }

        $from_machine | append $from_repo | uniq-by path-in-repo
    }
    | flatten
}

# Read paths-local.csv if it exists, otherwise return empty list
def open-local-configs [] {
    if ('paths-local.csv' | path exists) {
        open paths-local.csv | update full-path { path expand --no-symlink }
    } else { [] }
}

# Merge local and default configs, applying ignore/update status and deduplication
def assemble-paths [] {
    let local_statuses = open-local-configs
    | where status =~ '^update|ignore'
    | select full-path status

    open-configs
    | join --left $local_statuses full-path
    | where status? != ignore
}

# Copy config files from the local machine into the repository
export def pull-from-machine [
    --force # overwrite files with uncommitted changes
] {
    let paths = assemble-paths
    | where {|i| $i.full-path | path exists }

    if not $force and (check-dirty-files $paths path-in-repo "repo files") { return }

    $paths
    | group-by { $in.path-in-repo | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else { mkdir $dirname; $v }
    }
    | flatten
    | each { cp $in.full-path $in.path-in-repo }
}

# Copy config files from the repository to the local machine
export def push-to-machine [
    --create-dirs # in case of missing directories - create them in place
    --force # overwrite files with uncommitted changes
] {
    let paths = assemble-paths
    | where {|i| $i.path-in-repo | path exists }

    if not $force and (check-dirty-files $paths full-path "destination files") { return }

    $paths
    | group-by { $in.full-path | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else {
            if $create_dirs { mkdir $dirname; $v }
        }
    }
    | compact
    | flatten
    | each { cp $in.path-in-repo $in.full-path }
}

# Show a diff preview of what push-to-machine would change
export def preview-push-to-machine [] {
    assemble-paths
    | where {|i| $i.path-in-repo | path exists }
    | each {|row|
        if ($row.full-path | path exists) {
            # Shows what will change: diff current-local new-from-repo
            let diff = ^git diff --no-index $row.full-path $row.path-in-repo | complete
            if ($diff.stdout | is-not-empty) {
                print $"\n=== ($row.full-path) ==="
                $diff.stdout | lines | skip 4 | str join (char newline) | print
            }
        } else {
            print $"\n=== ($row.full-path) ==="
            print $"(ansi yellow)→ NEW FILE will be created(ansi reset)"
            if not ($row.full-path | path dirname | path exists) {
                print $"(ansi red)  ⚠ Parent directory does not exist: ($row.full-path | path dirname)(ansi reset)"
            }
        }
    }
}

# Scan tracked directories for new config files and update paths-local.csv
export def fill-candidates [] {
    let configs = open-configs

    let local_configs = open-local-configs

    let ignored_paths = $local_configs
    | where status? == 'ignore'
    | where {|i| $i.full-path | path exists }
    | upsert path-type {|i| $i.full-path | path type }

    let ignored_folders = $ignored_paths
    | where path-type == 'dir'
    | get full-path

    let regex = '\.^$*+?{}()[]|/' | split chars | each { $'\($in)' } | str join '|' | $"\(($in))"

    let ignored_folders_regex = $ignored_folders
    | str replace --all --regex $regex '\$1'
    | str join '|'
    | $"^($in)"

    let candidates = $configs
    | get full-path
    | path dirname
    | where $it != $nu.home-dir
    | uniq
    | each {
        path join '**/*'
        | into glob
        | try { ls $in | get name --optional }
    }
    | flatten
    | if $ignored_folders_regex == '^' { } else {
        where $it !~ $ignored_folders_regex
    }
    | where $it not-in $configs.full-path
    | where ($it | path type) == 'file'
    | wrap full-path

    $local_configs
    | where full-path? !~ $ignored_folders_regex and status? not-in ['ignore']
    | prepend ($ignored_paths | select full-path status --optional)
    | append $candidates
    | uniq-by full-path
    | sort-by full-path
    | default '' status
    | save -f paths-local.csv
}

const excluded_locals = [**/.git/** **/.jj/** toolkit.nu macos-fresh/* paths-default.csv README.md .gitignore CLAUDE.md .DS_Store .claude/settings.local.json paths-local.csv]

# List files in the repo that are not tracked in paths-default.csv
export def cleanup-paths-not-in-csv [] {
    let exist_paths = glob **/* --exclude $excluded_locals --no-dir

    let paths_in_csv = open-configs | get path-in-repo

    $exist_paths | path relative-to (pwd) | where $it not-in $paths_in_csv
}

# Migrate old two-column paths-default.csv to new single-column format
export def migrate-csv [
    --force # proceed even if derived paths don't match old paths
] {
    let csv = open paths-default.csv
    let columns = $csv | columns

    if 'path-in-repo' in $columns {
        # Check for mismatches between old path-in-repo and derived paths
        let mismatches = $csv | each {|row|
            let derived = derive-repo-path $row.full-path
            if $derived != $row.path-in-repo {
                {full-path: $row.full-path old: $row.path-in-repo derived: $derived}
            }
        } | compact

        if ($mismatches | is-not-empty) {
            print $"(ansi yellow)Warning: The following paths have custom mappings that differ from derived paths:(ansi reset)"
            $mismatches | each {|m|
                print $"  ($m.full-path)"
                print $"    old:     ($m.old)"
                print $"    derived: ($m.derived)"
            }
            if not $force {
                print $"\n(ansi red)Migration aborted. Use --force to proceed anyway.(ansi reset)"
                return
            }
            print $"\n(ansi yellow)Proceeding with --force. Custom mappings will be lost.(ansi reset)"
        }

        print "Migrating paths-default.csv from old format to new format..."
        $csv
        | each {|row|
            # Convert directory entries (trailing /) to glob patterns
            if ($row.full-path | str ends-with '/') {
                $row.full-path | str replace '/$' '/**/*'
            } else {
                $row.full-path
            }
        }
        | wrap full-path
        | save -f paths-default.csv
        print "Migration complete. Repo paths are now derived using convention:"
        print "  ~/.config/X/... → X/..."
        print "  ~/.X/...        → X/..."
    } else {
        print "paths-default.csv is already in the new format (single full-path column)."
    }
}
