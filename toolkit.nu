export def main [] { }

export def copy [] {
    glob '~/.config/nushell/{config,env}.nu'
    | each { cp $in nushell }

    cp ~/.config/nushell/autoload/ nushell -r

    cp ~/.config/wezterm/ . -r

    cp ~/.config/helix/ . -r

    cp ~/.config/zellij/ . -r

    cp ~/.config/ghostty/ . -r

    cp ~/.config/broot/ . -r
}
