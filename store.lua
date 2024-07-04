---@class PreferencesDocument: renoise.Document.DocumentNode
---@field watch renoise.Document.ObservableBoolean
---@field folder renoise.Document.ObservableString
---@field xrnx_id renoise.Document.ObservableString
---@field build_command renoise.Document.ObservableString
---@field build_log renoise.Document.ObservableString
---@field last_mtime renoise.Document.ObservableNumber
renoise.tool().preferences = renoise.Document.create("LiveReloadPreferences") {
  -- If watch mode is enabled
  watch = true,
  -- Absolute path to the project's folder on disk
  folder = "",
  -- ID from the xrnx manifest
  xrnx_id = "",
  -- The shell command to run
  build_command = "",
  -- A circular buffer of the last ~50 build log lines
  build_log = "",
  -- The last mtime of the xrnx file
  last_mtime = 0,
}

--- This isn't a data model we own; it's used to load files off the disk.
---@class ToolManifestDocument: renoise.Document.DocumentNode
---@field Id renoise.Document.ObservableString
renoise.Document.create("RenoiseScriptingTool"){
  Name = "",
  Id = "",
  Version = 0,
  ApiVersion = renoise.API_VERSION,
  Author = "",
  Category = "",
  Description = "",
  Homepage = "",
  Platform = "",
  Icon = "",
}

---@class Store
---@field state PreferencesDocument
---@field error_message renoise.Document.ObservableString
local store = {
  state = renoise.tool().preferences,
  -- todo track in mem log lines
  -- log_lines = renoise.Document.ObservableStringList(),
  error_message = renoise.Document.ObservableString(),
}

return store