# Dotfiles synchronization toolkit
#
# Manages syncing configuration files between this Git repository and the local machine.
# Uses two CSV files for configuration:
#   - paths-default.csv: Main list of tracked dotfiles (full-path, path-in-repo)
#   - paths-local.csv: Optional local overrides with status column (update, ignore)
#
# Commands:
#   pull-from-machine        - Copy configs from machine into repo
#   push-to-machine          - Copy configs from repo to machine
#   preview-push-to-machine  - Show diff of what push would change
#   fill-candidates          - Find new config files to potentially track
#   cleanup-paths-not-in-csv - List repo files not tracked in CSV

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

# Read paths-default.csv and expand all paths
def open-configs [] {
    open paths-default.csv
    | update full-path { path expand --no-symlink }
    | update path-in-repo { path expand --no-symlink }
}

# Read paths-local.csv if it exists, otherwise return empty list
def open-local-configs [] {
    'paths-local.csv'
    | if ($in | path exists) { open } else { [] }
    | update path-in-repo? { path expand --no-symlink }
}

# Merge local and default configs, applying ignore/update status and deduplication
def assemble-paths [] {
    open-local-configs
    | where status =~ '^update|ignore'
    | update path-in-repo { path expand --no-symlink } # needed for push-to-local-configs
    | append (open-configs)
    | uniq-by path-in-repo
    | where status? != ignore
}

# Copy config files from the local machine into the repository
export def pull-from-machine [
    --check-local-files-exist
    --force # overwrite files with uncommitted changes
] {
    let paths = assemble-paths
    | where {|i| $i.full-path | path exists }

    if not $force {
        let dirty = $paths | where { has-uncommitted-changes $in.path-in-repo }
        if ($dirty | is-not-empty) {
            print $"(ansi red)Error: The following repo files have uncommitted changes:(ansi reset)"
            $dirty | get path-in-repo | each { print $"  ($in)" }
            print $"\nCommit or stash changes first, or use --force to overwrite."
            return
        }
    }

    $paths
    | group-by { $in.path-in-repo | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else { mkdir $dirname; $v }
    }
    | compact
    | flatten
    | each { cp --recursive $in.full-path $in.path-in-repo }
}

# Copy config files from the repository to the local machine
export def push-to-machine [
    --create-dirs # in case of missing directories - create them in place
    --force # overwrite files with uncommitted changes
] {
    let paths = assemble-paths
    | where {|i| $i.path-in-repo | is-not-empty }

    if not $force {
        let dirty = $paths | where { has-uncommitted-changes $in.full-path }
        if ($dirty | is-not-empty) {
            print $"(ansi red)Error: The following destination files have uncommitted changes:(ansi reset)"
            $dirty | get full-path | each { print $"  ($in)" }
            print $"\nCommit or stash changes first, or use --force to overwrite."
            return
        }
    }

    $paths
    | group-by { $in.full-path | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else {
            if $create_dirs { mkdir $dirname; $v }
        }
    }
    | compact
    | flatten
    | each { cp --recursive $in.path-in-repo $in.full-path }
}

# Show a diff preview of what push-to-machine would change
export def preview-push-to-machine [] {
    assemble-paths
    | where {|i| $i.path-in-repo | is-not-empty }
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
    | where status? in ['ignore']
    | where {|i| $i.full-path | path exists }
    | upsert path-type {|i| $i.full-path | path type }

    let $ignored_files = $ignored_paths
    | where path-type == 'file'
    | get full-path

    let $ignored_folders = $ignored_paths
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
    | where $it != $nu.home-path
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

# List files in the repo that are not tracked in paths-default.csv
export def cleanup-paths-not-in-csv [] {
    let exist_paths = glob **/* --exclude [**/.git/** **/.jj/** toolkit.nu macos-fresh/* paths-default.csv README.md .gitignore] --no-dir

    let paths_in_csv = open paths-default.csv | get path-in-repo

    $exist_paths | path relative-to (pwd) | where $it not-in $paths_in_csv
}
