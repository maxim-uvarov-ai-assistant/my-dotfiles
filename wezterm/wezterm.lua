local wezterm = require 'wezterm'

-- ============================================================================
-- CONFIGURATION CONSTANTS
-- ============================================================================
local FONT_SIZE = 17.0
local ZEN_FONT_SIZE = 30
local INITIAL_COLS = 220
local INITIAL_ROWS = 220
local MAX_FPS = 255

-- Initialize configuration
local config = {}
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- ============================================================================
-- STARTUP & SHELL
-- ============================================================================
-- Helper function to find executable using system PATH and common locations
local function find_executable(cmd)
  -- Try system PATH first
  local handle = io.popen('which ' .. cmd .. ' 2>/dev/null')
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result and result ~= "" then
      return result
    end
  end

  -- Get user home directory dynamically
  local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

  -- Build dynamic common paths
  local common_paths = {}

  -- Add user-specific paths
  if home ~= "" then
    table.insert(common_paths, home .. "/.cargo/bin/")
    table.insert(common_paths, home .. "/.local/bin/")
    table.insert(common_paths, home .. "/bin/")
  end

  -- Add system paths based on platform
  local system_paths = {
    "/opt/homebrew/bin/", -- macOS Homebrew
    "/usr/local/bin/",    -- Common Unix
    "/usr/bin/",          -- Standard Unix
    "/bin/",              -- System binaries
  }

  for _, path in ipairs(system_paths) do
    table.insert(common_paths, path)
  end

  -- Check each path
  for _, path in ipairs(common_paths) do
    local full_path = path .. cmd
    local file = io.open(full_path, "r")
    if file then
      file:close()
      return full_path
    end
  end

  return nil
end

-- Find executables and build shell command with fallbacks
local function setup_shell()
  local nu_path = find_executable('nu')
  if nu_path then
    local zellij_path = find_executable('zellij')
    if zellij_path then
      -- Use zellij with nushell
      config.default_prog = { nu_path, '-l', '--execute', 'zellij attach -c prophet' }
      return
    else
      -- Use nushell without zellij
      config.default_prog = { nu_path }
      return
    end
  end

  -- Fallback to system default shell if nu is not available
  -- WezTerm will use the system default shell if default_prog is not set
  wezterm.log_info("Nushell not found, using system default shell")
end

-- Setup shell with error handling
local ok, err = pcall(setup_shell)
if not ok then
  wezterm.log_error("Error setting up shell: " .. tostring(err))
end
config.check_for_updates = false

-- ============================================================================
-- ENVIRONMENT
-- ============================================================================
-- Set XDG directories dynamically based on platform
local function setup_environment()
  local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""
  local config_env = {}

  if home ~= "" then
    config_env.XDG_CONFIG_HOME = home .. "/.config"
    config_env.XDG_DATA_HOME = home .. "/.local/share"
  else
    wezterm.log_warn("Unable to determine home directory, XDG variables not set")
  end

  return config_env
end

-- Setup environment with error handling
local env_ok, env_vars = pcall(setup_environment)
if env_ok and env_vars then
  config.set_environment_variables = env_vars
else
  wezterm.log_error("Error setting up environment variables")
  config.set_environment_variables = {}
end

-- ============================================================================
-- APPEARANCE
-- ============================================================================
-- Font configuration
config.font = wezterm.font { family = 'ZedMono Nerd Font', stretch = 'Expanded' }
config.font_size = FONT_SIZE

-- Window settings
config.initial_cols = INITIAL_COLS
config.initial_rows = INITIAL_ROWS
config.hide_tab_bar_if_only_one_tab = true

-- Platform-specific settings
local is_macos = wezterm.target_triple:find("darwin") ~= nil
if is_macos then
  config.native_macos_fullscreen_mode = true
end

-- ============================================================================
-- PERFORMANCE
-- ============================================================================
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = MAX_FPS
config.animation_fps = MAX_FPS

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
  { key = 'v', mods = 'CMD',        action = wezterm.action.PasteFrom 'Clipboard' },
  { key = '=', mods = 'CMD',        action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CMD',        action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CMD',        action = wezterm.action.ResetFontSize },
  { key = 'q', mods = 'CMD',        action = wezterm.action.QuitApplication },
}

-- ============================================================================
-- QUICK SELECT PATTERNS
-- ============================================================================
local quick_select_patterns = {
  -- Nushell error paths (like ╭─[/path/to/file.nu:1946:63])
  "─\\[(.*\\:\\d+\\:\\d+)\\]",

  -- Table patterns
  -- $env.config.table.mode = "default"
  -- $env.config.table.header_on_separator = true
  -- $env.config.footer_mode = "Always"
  "(?<=─|╭|┬)([a-zA-Z0-9 _%.-]+?)(?=─|╮|┬)", -- Headers
  "(?<=│ )([a-zA-Z0-9 _.-]+?)(?= │)", -- Column values

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
      overrides.font_size = ZEN_FONT_SIZE
    else
      overrides.font_size = nil
    end
  end
  window:set_config_overrides(overrides)
end)

return config
