local util = require "util"

---@alias State {error_message: renoise.Document.ObservableString}

---@class Store
---@field private preferences PreferencesDocument
---@field watch boolean
---@field folder string
---@field xrnx_id string
---@field build_command string
---@field build_log string
---@field last_mtime integer
---@field private state State
---@field error_message string
local Store = {}

local active_effect = nil

Store.__index = function (t, k)
  if Store[k] ~= nil then return Store[k] end

  local field = t.preferences[k] ~= nil and "preferences" or "state"

  local target = rawget(t, field)[k]

  if not target then return nil end

  if active_effect then
    -- TODO: we should track the subscriptions so we can drop them if they change
    -- For example: `watch_effect(function () if store.a then store.b else store.c end)`
    if not target:has_notifier(active_effect) then
      target:add_notifier(active_effect)
    end
  end

  if string.sub(type(target), -4) == "List" then
    local v = {}
    for i=1,#target do
      v[i] = target[i].value
    end
    return v
  end

  return target.value
end

Store.__newindex = function (t, k, v)
  local field = t.preferences[k] ~= nil and "preferences" or "state"
  local target = rawget(t, field)[k]

  if not target then return end

  if string.sub(type(target), -4) == "List" then
    for i=1,#v do
      target[i].value = v[i]
    end
    return
  end

  target.value = v
end

---@return Store
function Store:new()
  return setmetatable({
    preferences = renoise.tool().preferences,
    state = {
      error_message = renoise.Document.ObservableString(),
    },
  }, Store)
end

function Store:watch_effect(cb)
  active_effect = cb
  cb()
  active_effect = nil
end

---@alias Workspace {path: string, xrnx_id: string, build_command: string}

---@param workspace Workspace
function Store:set_workspace(workspace)
  if self.folder ~= workspace.path then
    self.folder = workspace.path
    self.xrnx_id = workspace.xrnx_id
    self.build_command = workspace.build_command
    self.build_log = ""
    self.last_mtime = 0
  end
end


---@return Workspace
function Store:workspace()
  return {
    path = self.folder,
    xrnx_id = self.xrnx_id,
    build_command = self.build_command,
  }
end

function Store:clear_build_log()
  self.build_log = ""
end

---@param line string
function Store:log(line)
  self.build_log = self.build_log .. "\n" .. line
end

---@param mtime integer
---@return integer
function Store:swap_mtime(mtime)
  local last_mtime = self.last_mtime
  self.last_mtime = mtime
  return last_mtime
end

return Store