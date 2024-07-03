local tool = renoise.tool()

---@class PreferencesDocument: renoise.Document.DocumentNode
---@field watch renoise.Document.ObservableBoolean
---@field active_project renoise.Document.ObservableString
---@field recent_projects renoise.Document.ObservableStringList
---@field build_dialog_opened renoise.Document.ObservableBoolean
renoise.tool().preferences = renoise.Document.create("LiveReloadPreferences") {
  watch = true,
  active_project = "",
  recent_projects = renoise.Document.ObservableStringList(),
  build_dialog_opened = false,
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

---@class ProjectDocument: renoise.Document.DocumentNode
---@field folder renoise.Document.ObservableString
---@field xrnx_id renoise.Document.ObservableString
---@field build_command renoise.Document.ObservableString
---@field build_log renoise.Document.ObservableStringList
---@field last_mtime renoise.Document.ObservableNumber
renoise.Document.create("LiveReloadProject") {
  -- Absolute path to the project's folder on disk
  folder = "",
  -- ID from the xrnx manifest
  xrnx_id = "",
  -- The shell command to run
  build_command = "",
  -- A circular buffer of the last ~50 build log lines
  build_log = renoise.Document.ObservableStringList(),
  -- The last mtime of the xrnx file
  last_mtime = 0,
}

---@class Store
---@field preferences PreferencesDocument
---@field project ProjectDocument?
local store = {
  preferences = renoise.tool().preferences,
  project = nil,
}

return store