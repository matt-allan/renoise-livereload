local util = require "util"
local tool = renoise.tool()

local action = {}

---@param store Store
---@param path string
function action.open_project(store, path)
  local manifest_path = util.path_join(path, "manifest.xml")

  if not io.exists(manifest_path) then
    store.error_message.value = string.format("Manifest not found at path %s", manifest_path)
    return
  end

  local manifest_doc = renoise.Document.instantiate("RenoiseScriptingTool")

  local ok, err = manifest_doc:load_from(manifest_path)

  if not ok then
    store.error_message.value = string.format("Error loading manifest: %s", err)
    return
  end

  local xrnx_id = manifest_doc["Id"].value

  if not xrnx_id then
    store.error_message.value = "Manifest field 'Id' not found"
    return
  end

  if store.state.folder.value ~= path then
    store.state.folder.value = path
    store.state.xrnx_id.value = xrnx_id
    store.state.build_command.value = util.detect_build_command(path, xrnx_id..".xrnx")
    store.state.build_log.value = ""
    store.state.last_mtime.value = 0
  end
end

---@param store Store
---@param value string
function action.set_build_command(store, value)
  store.state.build_command.value = util.str_trim(value)
end

---@param store Store
---@param value boolean
function action.set_watch(store, value)
  store.state.watch.value = value
end

---@param store Store
function action.clear_build_log(store)
  store.state.build_log.value = ""
  -- while store.log_lines:size() > 0 do
  --   store.log_lines:remove()
  -- end
end

---@param store Store
---@param msg string
function action.log(store, msg)
  local line = string.format("[%s] %s", os.date("%c"), msg)

  store.state.build_log.value = store.state.build_log.value .. "\n" .. line
end

function action.sync_logs(store)
  -- todo
end

---@param store Store
function action.spawn_build(store)
  local log = function (msg) action.log(store, msg) end

  log("Starting build")

  local folder = store.state.folder.value
  local xrnx_id = store.state.xrnx_id.value
  local build_cmd = store.state.build_command.value

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
    action.sync_logs(store)
    return
  end

  local stat, stat_err = io.stat(xrnx_path)
  if not stat then
    log(string.format("ERROR: Stat error: %s", stat_err))
  else
    local last_mtime = store.state.last_mtime.value
    store.state.last_mtime.value = stat.mtime
    if stat.mtime == last_mtime then
      log("No changes")
      return
    end
  end

  log("Installing...")
  action.sync_logs(store)
  renoise.app():install_tool(xrnx_path)
end

return action