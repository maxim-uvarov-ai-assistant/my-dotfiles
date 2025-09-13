let configs = open configs_list.csv
| update full-path { path expand }

let local_configs = 'local-configs.csv'
| if ($in | path exists) { open } else { [] }

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
| default '' status
| save -f local-configs.csv
