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

export def push-to-local-configs [] {
    $dirs
    | wrap dot-config
    | insert source {|i|
        $i.dot-config
        | path basename
        | path join **/*
        | glob $in --no-dir
        | each {
            path relative-to (pwd)
            | path split
            | skip
            | path join
        }
    }
    | flatten
    | insert destination {|i| $i.dot-config | path join $i.source }
    | each {|i| cp $i.source $i.destination }
    | print $'files copied ($in | length)'
}
