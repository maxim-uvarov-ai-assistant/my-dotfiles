local wezterm = require 'wezterm'

local config = {}

config.native_macos_fullscreen_mode = true

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

-- Allow working with both the current release and the nightly
if wezterm.config_builder then
  config = wezterm.config_builder()
end


-- config.use_ime = false
-- config.debug_key_events = true

config.default_prog = { '/Users/user/.cargo/bin/nu', '-l', '--execute', 'zellij attach -c prophet' }
-- config.default_prog = { '/opt/homebrew/bin/zellij', 'attach', '-c', 'prophet'}
-- config.default_prog = { '/opt/homebrew/bin/zellij' }
-- config.default_prog = { '/opt/homebrew/bin/nu', '-l'}

config.check_for_updates = false
config.set_environment_variables = {
    XDG_CONFIG_HOME = '/Users/user/.config',
    XDG_DATA_HOME = '/Users/user/.local/share'
}

-- config.font = wezterm.font { family = 'JetBrainsMono Nerd Font' }
-- config.font = wezterm.font { family = 'Consolas' }
-- config.font = wezterm.font { family = 'Departure Mono'}
-- config.font = wezterm.font { family = 'Cascadia Code' }
-- config.font = wezterm.font { family = 'Iosevka Extended'}

-- https://www.nerdfonts.com/font-downloads
-- brew install --cask font-zed-mono-nerd-font
config.font = wezterm.font { family = 'ZedMono Nerd Font', stretch = 'Expanded' }

config.font_size = 17.0
config.initial_cols = 220
config.initial_rows = 220
config.switch_to_last_active_tab_when_closing_tab = true
config.skip_close_confirmation_for_processes_named = {
  'bash',
  'sh',
  'zsh',
  'fish',
  'tmux',
  'nu',
}

config.enable_kitty_keyboard = true

-- config.scrollback_lines = 10000

config.disable_default_key_bindings = true
config.hide_tab_bar_if_only_one_tab = true

config.keys = {
  -- {
  --   key = 'Enter',
  --   mods = 'ALT',
  --   action = wezterm.action.DisableDefaultAssignment,
  -- },
  -- {
  --   key = 'q',
  --   mods = 'SHIFT|CTRL',
  --   action = wezterm.action.DisableDefaultAssignment,
  -- },
  -- {
  --   key = 'f',
  --   mods = 'SHIFT|CTRL',
  --   action = wezterm.action.DisableDefaultAssignment,
  -- },
  -- {
  --   key = 'h',
  --   mods = 'ALT|CMD',
  --   action = wezterm.action.DisableDefaultAssignment,
  -- },
  -- {
  --   key = 'Delete',
  --   mods = '',
  --   action = act.SendKey { key = 'Delete' },
  -- },
  -- {
  --   key = 'w',
  --   mods = 'CMD',
  --   action = wezterm.action.CloseCurrentPane { confirm = false },
  -- },
  -- {
  --   key = 'UpArrow',
  --   mods = 'CTRL|CMD',
  --   action = wezterm.action.Search { Regex = '^>' },
  -- },
  -- {
  --   key = "T",
  --   mods = "CMD|SHIFT",
  --   action = wezterm.action.SpawnCommandInNewTab {
  --     cwd = "/Users/user/temp"
  --   },
  -- },
  -- {
  --   key = 'k',
  --   mods = 'CMD',
  --   action = wezterm.action.Multiple {
  --     wezterm.action.SendKey { key = 'L', mods = 'CTRL' },
  --     wezterm.action.ClearScrollback 'ScrollbackAndViewport',
  --   },
  -- },
  { key = ' ', mods = 'SHIFT|CTRL', action = wezterm.action.QuickSelect },
  { key = 'x', mods = 'SHIFT|CTRL', action = wezterm.action.ActivateCopyMode },
  { key = 'v', mods = 'CMD', action = wezterm.action.PasteFrom 'Clipboard'},
  { key = '=', mods = 'CMD', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD', action = wezterm.action.ResetFontSize },
  { key = 'q', mods = 'CMD', action = wezterm.action.QuitApplication },
}

config.mouse_wheel_scrolls_tabs = false
config.quick_select_patterns = {
  "[0-9A-F]{64}",
  "bostrom1[a-z0-9]{38}",

  "\\[(.*)\\]", --errors of nushell scripts
  -- "\\$.*?\s",
  "(?<=─|╭|┬)([a-zA-Z0-9 _%.-]+?)(?=─|╮|┬)", --headers pattern
  -- "(?<=> |❯ )(.+)(?=  )", --commands pattern
  "(?<=> |❯ )([^ ].+?)(?=  )", --command prompt pattern
  -- "(?<=│ )([^ ].+?)(?= │)", --list and column values pattern
  "(?<=│ )([a-zA-Z0-9 _.-]+?)(?= │)", --list and column values pattern
  -- "(?<=^ )(.+?)(?= │)", --visidata pattern
}

config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 255
config.animation_fps = 255



return config
