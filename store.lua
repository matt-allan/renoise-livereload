local util = require "util"

---@class Store
---@field preferences PreferencesDocument
---@field watch boolean
---@field folder string
---@field xrnx_id string
---@field build_command string
---@field build_log string
---@field last_mtime integer
---@field mem {error_message: renoise.Document.ObservableString}
---@field error_message string
local Store = {}

local active_effect = nil

Store.__index = function (t, k)
  if Store[k] ~= nil then return Store[k] end

  local field = t.preferences[k] ~= nil and "preferences" or "mem"

  local target = rawget(t, field)[k]

  if not target then return nil end

  if active_effect then
    if not target:has_notifier(active_effect) then
      target:add_notifier(active_effect)
    end
  end

  return target.value
end

Store.__newindex = function (t, k, v)
  local field = t.preferences[k] ~= nil and "preferences" or "mem"
  local target = rawget(t, field)[k]

  if not target then return end

  target.value = v
end

---@return Store
function Store:new()
  return setmetatable({
    -- persistent state
    -- TODO: make private once can subscribe without notifiers
    preferences = renoise.tool().preferences,
    -- ephemeral state
    mem = {
      -- todo track in mem log lines
      -- log_lines = renoise.Document.ObservableStringList(),
      error_message = renoise.Document.ObservableString(),
    },
  }, Store)
end

function Store:watch_effect(cb)
  active_effect = cb
  cb()
  active_effect = nil
end

---@param path string?
function Store:open_project(path)
  path = path or self.folder
  if not path or path == "" then return end

  local manifest_path = util.path_join(path, "manifest.xml")

  if not io.exists(manifest_path) then
    self.error_message = string.format("Manifest not found at path %s", manifest_path)
    return
  end

  local manifest_doc = renoise.Document.instantiate("RenoiseScriptingTool")

  local ok, err = manifest_doc:load_from(manifest_path)

  if not ok then
    self.error_message = string.format("Error loading manifest: %s", err)
    return
  end

  local xrnx_id = manifest_doc["Id"].value

  if not xrnx_id then
    self.error_message = "Manifest field 'Id' not found"
    return
  end

  if self.folder ~= path then
    self.folder = path
    self.xrnx_id = xrnx_id
    self.build_command = util.detect_build_command(path, xrnx_id..".xrnx")
    self.build_log = ""
    self.last_mtime = 0
  end
end

---@param value string
function Store:set_build_command(value)
  self.build_command = util.str_trim(value)
end

---@param value boolean
function Store:set_watch(value)
  self.watch = value
end

function Store:clear_build_log()
  self.build_log = ""
end

---@param msg string
function Store:log(msg)
  local line = string.format("[%s] %s", os.date("%c"), msg)

  self.build_log = self.build_log .. "\n" .. line
end

function Store:sync_logs()
  -- todo
end

function Store:spawn_build()
  local log = function (msg) self:log(msg) end

  log("Starting build")

  local folder = self.folder
  local xrnx_id = self.xrnx_id
  local build_cmd = self.build_command

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
    local last_mtime = self.last_mtime
    self.last_mtime = stat.mtime
    if stat.mtime == last_mtime then
      log("No changes")
      return
    end
  end

  log("Installing...")
  self:sync_logs()
  renoise.app():install_tool(xrnx_path)
end

return Store