# Create isolated overlay for external tools
overlay new others
source /Users/user/.config/broot/launcher/nushell/br

# # moved to autloads
# source /Users/user/git/nu_scripts/sourced/standard_4002_aliasses.nu
# source /Users/user/git/my_nu_completions/my_nu_completions.nu

# Nushell Modules
overlay use /Users/user/git/nu-goodies/nu-goodies
# overlay use /Users/user/git/nushell-kv/kv --prefix
overlay use /Users/user/git/dotnu/dotnu --prefix
overlay use /Users/user/git/numd/numd --prefix

# Specialized Tools
# use /Users/user/git/nushell-openai/openai.nu ask
# use /Users/user/git/nushell-openai/correct-english.nu

# use /Users/user/git/npshow-module/npshow
# use /Users/user/git/todo
# use /Users/user/git/nu-critic-markup/commands.nu *

