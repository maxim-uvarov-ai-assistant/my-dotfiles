local wezterm = require 'wezterm'

-- Initialize config
local config = wezterm.config_builder and wezterm.config_builder() or {}

-- Constants
local HOME = '/Users/user'
local FONT_SIZE = 17.0
local FONT_SIZE_ZEN = 30.0
local INITIAL_COLS = 120
local INITIAL_ROWS = 120

-- Performance settings
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 255
config.animation_fps = 255

-- Window and display settings
config.native_macos_fullscreen_mode = true
config.initial_cols = INITIAL_COLS
config.initial_rows = INITIAL_ROWS
config.hide_tab_bar_if_only_one_tab = true

-- Color scheme
config.colors = {
    background = '#0a0e1a',  -- Dark blue, almost black
}

-- Font configuration
config.font = wezterm.font { family = 'ZedMono Nerd Font', stretch = 'Expanded' }
config.font_size = FONT_SIZE

-- Default shell and environment
config.set_environment_variables = {
    XDG_CONFIG_HOME = HOME .. '/.config'
}
config.default_prog = { '/opt/homebrew/bin/nu', '-l', '--execute', 'zellij attach -c prophet' }

-- Behavior settings
config.check_for_updates = false
config.switch_to_last_active_tab_when_closing_tab = true
config.skip_close_confirmation_for_processes_named = {
    'bash', 'sh', 'zsh', 'fish', 'tmux', 'nu',
}
config.enable_kitty_keyboard = true
config.mouse_wheel_scrolls_tabs = false

-- Event handlers
wezterm.on('user-var-changed', function(window, pane, name, value)
    local overrides = window:get_config_overrides() or {}
    if name == "ZEN_MODE" then
        if value == "on" then
            overrides.font_size = FONT_SIZE_ZEN
        else
            overrides.font_size = nil
        end
    end
    window:set_config_overrides(overrides)
end)

-- Key bindings
config.disable_default_key_bindings = true
config.keys = {
    { key = ' ', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect},
    { key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
    { key = 'x', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCopyMode },
    { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard' },
    { key = '=', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
    { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
    { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
    { key = 'q', mods = 'CMD', action = wezterm.action.QuitApplication },
}

-- Quick select patterns
config.quick_select_patterns = {
    -- Hex hashes
    "[0-9A-F]{64}",
    -- Bostrom addresses
    "bostrom1[a-z0-9]{38}",
    -- Nushell errors
    "\\[(.*)\\]",
    -- Table headers
    "(?<=─|╭|┬)([a-zA-Z0-9 _%.-]+?)(?=─|╮|┬)",
    -- Command prompt
    "(?<=> |❯ )([^ ].+?)(?=  )",
    -- Table cell values
    "(?<=│ )([a-zA-Z0-9 _.-]+?)(?= │)",
}

return config
