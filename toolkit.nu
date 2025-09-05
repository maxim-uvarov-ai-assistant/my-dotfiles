export def main [] { }

const dirs =  [
        '~/.config/wezterm/'
        '~/.config/helix/'
        '~/.config/zellij/'
        '~/.config/ghostty/'
        '~/.config/broot/'
    ]

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
