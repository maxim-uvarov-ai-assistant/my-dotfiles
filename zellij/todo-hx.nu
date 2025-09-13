#!/usr/bin/env nu

mkdir todo

# cd todo

let date = date now | format date '%+' | str substring ..15

let path = $date
| str replace --all -r '[^\dT]' ''
| str replace T '-'
| $'todo/($in).md'

let $frontmatter = {
    task-name: ''
    status: 'draft'
    update: ($date | str replace T ' ')
} | to yaml
| str replace -r "\n$" ""
| prepend '---'
| append '---'
| to text

mkdir todo/

if not ($path | path exists) {
    $frontmatter | save $path
}

hx $path

open $path
| if $in == $frontmatter { rm $path }
# cd ..

if (ls 'todo' | is-empty) { rm 'todo' }
