
# let options = tte --help
# let styles = $options | parse -r '\{(.+)\}' | get capture0.0 | split row ','
# let params = $options | lines | skip until {|it| $it =~ 'options'} | take until {|it| $it =~ 'Effect:'} | skip | parse -r '(--\S+)' | get capture0 | str join $'(char nl)    '
# 
# $"
# def nu-complete-tte-style-completions [] {
#     ($styles)
# }
# 
# export extern tte [
#     style: string@'nu-complete-tte-style-completions'
#     ($params)
# ]
# "

def nu-complete-tte-style-completions [] {
    [beams, binarypath, blackhole, bouncyballs, bubbles, burn, colorshift, crumble, decrypt, errorcorrect, expand, fireworks, middleout, orbittingvolley, overflow, pour, print, rain, randomsequence, rings, scattered, slice, slide, spotlights, spray, swarm, synthgrid, unstable, vhstape, waves, wipe]
}

export extern tte [
    style: string@'nu-complete-tte-style-completions'
    --help
    --input-file
    --tab-width
    --xterm-colors
    --no-color
    --wrap-text
    --frame-rate
    --canvas-width
    --canvas-height
    --ignore-terminal-dimensions]

def nu-complete-code2prompt [] {
    glob /Users/user/git/code2prompt/templates/*.hbs
}


export extern "code2prompt" [
	--include # Patterns to include
	--exclude # Patterns to exclude
	--include-priority # Include files in case of conflict between include and exclude patterns
	--exclude-from-tree # Exclude files/folders from the source tree based on exclude patterns
	--tokens # Display the token count of the generated prompt
	--encoding(-c) # Optional tokenizer to use for token count
	--output(-o) # Optional output file path
	--diff(-d) # Include git diff
	--git-diff-branch # Generate git diff between two branches
	--git-log-branch # Retrieve git log between two branches
	--line-number(-l) # Add line numbers to the source code
	--no-codeblock # Disable wrapping code inside markdown code blocks
	--relative-paths # Use relative paths instead of absolute paths, including the parent directory
	--no-clipboard # Optional Disable copying to clipboard
	--template(-t): string@nu-complete-code2prompt # Optional Path to a custom Handlebars template
	--json # Print output as JSON
	--help(-h) # Print help (see a summary with '-h')
	--version(-V) # Print version
	...args
]
