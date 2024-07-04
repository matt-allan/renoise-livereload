local xml = {}

function xml.init()
  ---@class PreferencesDocument: renoise.Document.DocumentNode
  ---@field watch renoise.Document.ObservableBoolean If watch mode is enabled
  ---@field folder renoise.Document.ObservableString Absolute path to the project's folder on disk
  ---@field xrnx_id renoise.Document.ObservableString ID from the xrnx manifest
  ---@field build_command renoise.Document.ObservableString The shell command to run
  ---@field build_log renoise.Document.ObservableString A circular buffer of the last ~50 build log lines
  ---@field last_mtime renoise.Document.ObservableNumber The last mtime of the xrnx file
  renoise.tool().preferences = renoise.Document.create("LiveReloadPreferences") {
    watch = true,
    folder = "",
    xrnx_id = "",
    build_command = "",
    build_log = "",
    last_mtime = 0,
  }

  ---The xml document used for a tool's `manifest.xml`.
  ---This isn't a data model we own; it's used to load files off the disk.
  ---@class ToolManifestDocument: renoise.Document.DocumentNode
  renoise.Document.create("RenoiseScriptingTool"){
    Name = "",
    Id = "",
    Version = 0.1,
    ApiVersion = renoise.API_VERSION,
    Author = "",
    Category = "",
    Description = "",
    Homepage = "",
    Platform = "",
    Icon = "",
  }
end

return xml