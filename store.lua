local util = require "util"

---@class Store
---@field state PreferencesDocument
---@field error_message renoise.Document.ObservableString
local store = {
  state = renoise.tool().preferences,
  -- todo track in mem log lines
  -- log_lines = renoise.Document.ObservableStringList(),
  error_message = renoise.Document.ObservableString(),
}

---@param path string?
function store:open_project(path)
  path = path or store.state.folder.value
  if not path or path == "" then return end

  local manifest_path = util.path_join(path, "manifest.xml")

  if not io.exists(manifest_path) then
    self.error_message.value = string.format("Manifest not found at path %s", manifest_path)
    return
  end

  local manifest_doc = renoise.Document.instantiate("RenoiseScriptingTool")

  local ok, err = manifest_doc:load_from(manifest_path)

  if not ok then
    self.error_message.value = string.format("Error loading manifest: %s", err)
    return
  end

  local xrnx_id = manifest_doc["Id"].value

  if not xrnx_id then
    self.error_message.value = "Manifest field 'Id' not found"
    return
  end

  if self.state.folder.value ~= path then
    self.state.folder.value = path
    self.state.xrnx_id.value = xrnx_id
    self.state.build_command.value = util.detect_build_command(path, xrnx_id..".xrnx")
    self.state.build_log.value = ""
    self.state.last_mtime.value = 0
  end
end

---@param value string
function store:set_build_command(value)
  self.state.build_command.value = util.str_trim(value)
end

---@param value boolean
function store:set_watch(value)
  self.state.watch.value = value
end

function store:clear_build_log()
  self.state.build_log.value = ""
end

---@param msg string
function store:log(msg)
  local line = string.format("[%s] %s", os.date("%c"), msg)

  self.state.build_log.value = self.state.build_log.value .. "\n" .. line
end

function store:sync_logs()
  -- todo
end

function store:spawn_build()
  local log = function (msg) self:log(msg) end

  log("Starting build")

  local folder = self.state.folder.value
  local xrnx_id = self.state.xrnx_id.value
  local build_cmd = self.state.build_command.value

  log(string.format("Executing build command `%s`", build_cmd))
  local command = string.format(
    "cd %q && %s",
    folder,
    build_cmd
  )
  local exit_code = os.execute(command)
  log(string.format("build finished with code %d", exit_code))

  local xrnx_path = util.path_join(folder, xrnx_id)..".xrnx"

  if not io.exists(xrnx_path) then
    log("ERROR: No xrnx generated")
    self:sync_logs()
    return
  end

  local stat, stat_err = io.stat(xrnx_path)
  if not stat then
    log(string.format("ERROR: Stat error: %s", stat_err))
  else
    local last_mtime = self.state.last_mtime.value
    self.state.last_mtime.value = stat.mtime
    if stat.mtime == last_mtime then
      log("No changes")
      return
    end
  end

  log("Installing...")
  self:sync_logs()
  renoise.app():install_tool(xrnx_path)
end

return store