#!/usr/bin/env nu

mkdir todo

# cd todo

let date = date now | format date '%+' | str substring ..15 | str replace --all -r '[^\dT]' '' | str replace T '-'

let path = $'todo/($date).md'

hx $path

# cd ..

if (ls 'todo' | is-empty) { rm 'todo' }
