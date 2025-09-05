export def main [] { }

const dirs = [
    '~/.config/wezterm/'
    '~/.config/helix/'
    '~/.config/zellij/'
    '~/.config/ghostty/'
    '~/.config/broot/'
] | path expand

export def pull-from-local-configs [] {
    glob '~/.config/nushell/{config,env}.nu'
    | each { cp $in nushell }

    cp ~/.config/nushell/autoload/ nushell -r

    $dirs
    | each {
        path expand
        | if ($in | path exists) { cp $in . -r }
    }
}

export def push-to-local-configs [
    --create-dirs # in case of missing directories - create them in place
] {
    open configs_list.csv
    | update full-path { path expand --no-symlink }
    | insert dirname { $in.full-path | path dirname }
    | group-by dirname
    | items {|dirname v|
        if ($dirname | path exists) { $v } else {
            if $create_dirs { mkdir $dirname; $v }
        }
    }
    | compact
    | flatten
    | each {cp $in.path-in-repo $in.full-path}
}
