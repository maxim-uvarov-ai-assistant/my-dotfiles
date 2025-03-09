export def main [] { }

export def copy [] {
    glob '~/.config/nushell/{config,env}.nu'
    | each { cp $in nushell }

    cp ~/.wezterm.lua .

    cp ~/.config/ghostty . -r

    cp ~/.config/helix/ . -r
}
