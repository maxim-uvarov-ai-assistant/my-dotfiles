local wezterm = require 'wezterm'

-- Initialize configuration
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- ============================================================================
-- STARTUP & SHELL
-- ============================================================================
config.default_prog = { '/Users/user/.cargo/bin/nu', '-l', '--execute', 'zellij attach -c prophet' }
config.check_for_updates = false

-- ============================================================================
-- ENVIRONMENT
-- ============================================================================
config.set_environment_variables = {
    XDG_CONFIG_HOME = '/Users/user/.config',
    XDG_DATA_HOME = '/Users/user/.local/share'
}

-- ============================================================================
-- APPEARANCE
-- ============================================================================
-- Font configuration
config.font = wezterm.font { family = 'ZedMono Nerd Font', stretch = 'Expanded' }
config.font_size = 17.0

-- Window settings
config.initial_cols = 220
config.initial_rows = 220
config.native_macos_fullscreen_mode = true
config.hide_tab_bar_if_only_one_tab = true

-- ============================================================================
-- PERFORMANCE
-- ============================================================================
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 255
config.animation_fps = 255

-- ============================================================================
-- BEHAVIOR
-- ============================================================================
config.switch_to_last_active_tab_when_closing_tab = true
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
}
config.mouse_wheel_scrolls_tabs = false
config.enable_kitty_keyboard = true

-- ============================================================================
-- KEY BINDINGS
-- ============================================================================
config.disable_default_key_bindings = true
config.keys = {
  { key = ' ', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
  { key = 'x', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCopyMode },
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard'},
  { key = '=', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
  { key = 'q', mods = 'CMD', action = wezterm.action.QuitApplication },
}

-- ============================================================================
-- QUICK SELECT PATTERNS
-- ============================================================================
local quick_select_patterns = {
  -- Crypto addresses
  "[0-9A-F]{64}",                                                      -- Hash
  "bostrom1[a-z0-9]{38}",                                             -- Bostrom address
  
  -- Nushell error paths (like ╭─[/path/to/file.nu:1946:63])
  "─\\[(.*\\:\\d+\\:\\d+)\\]",
  
  -- Table patterns
  "(?<=─|╭|┬)([a-zA-Z0-9 _%.-]+?)(?=─|╮|┬)",                        -- Headers
  "(?<=│ )([a-zA-Z0-9 _.-]+?)(?= │)",                                -- Column values
  
  -- File paths (stops at ~)
  "/[^/\\s│~]*(?:\\s+[^/\\s│~]*)*(?:/[^/\\s│~]*(?:\\s+[^/\\s│~]*)*)*",
}

config.quick_select_patterns = quick_select_patterns

-- ============================================================================
-- DYNAMIC CONFIGURATION (ZEN MODE)
-- ============================================================================
-- Demo mode for screencasts. Activate in wezterm (outside of zellij) via:
-- 'on' | encode base64 | $"\e]1337;SetUserVar=ZEN_MODE=($in)\e"
-- 'off' | encode base64 | $"\e]1337;SetUserVar=ZEN_MODE=($in)\e"
wezterm.on('user-var-changed', function(window, pane, name, value)
  local overrides = window:get_config_overrides() or {}
  if name == "ZEN_MODE" then
     if value == "on" then
       overrides.font_size = 30
     else
       overrides.font_size = nil
    end
  end
  window:set_config_overrides(overrides)
end)

return config