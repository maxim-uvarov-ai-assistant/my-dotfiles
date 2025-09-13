export def main [] { }

def open-configs [] {
    open paths-default.csv
    | update full-path { path expand --no-symlink }
}

def open-local-configs [] {
    'local-configs.csv'
    | if ($in | path exists) { open } else { [] }
}

export def pull-from-local-configs [
    --check-local-files-exist
] {
    open-configs
    | update path-in-repo { path expand --no-symlink }
    | where {|i| $i.full-path | path exists }
    | group-by { $in.path-in-repo | path dirname }
    | items {|dirname v|
        if ($dirname | path exists) { $v } else { mkdir $dirname; $v }
    }
    | compact
    | flatten
    | each { cp $in.full-path $in.path-in-repo }
}

export def push-to-local-configs [
    --create-dirs # in case of missing directories - create them in place
] {
    open-configs
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

export def fill-candidates [] {
    let configs = open-config

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
    | save -f local-configs.csv
}
