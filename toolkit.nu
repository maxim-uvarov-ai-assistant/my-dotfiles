export def main [] { }

export def copy [] {
    glob '~/.config/nushell/{config,env}.nu'
    | each { cp $in nushell }
}
