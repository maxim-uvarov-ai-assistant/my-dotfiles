export def main [] { }

export def pull-from-local-configs [
    --check-local-files-exist
] {
    open configs_list.csv
    | update path-in-repo { path expand --no-symlink }
    | update full-path { path expand --no-symlink }
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
    open configs_list.csv
    | update full-path { path expand --no-symlink }
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
