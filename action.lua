local util = require "util"
local tool = renoise.tool()

local action = {}

local project_dir = util.path_join(tool.bundle_path, "Projects")

local function project_file_name(xrnx_id)
  return util.path_join(project_dir, xrnx_id) .. ".xml"
end

---@param project ProjectDocument
local function save_project(project)
  return project:save_as(project_file_name(project.xrnx_id.value))
end

---@param store Store
function action.boot(store)
  if store.preferences.active_project.value then
    action.open_project(store, store.preferences.active_project.value)
  end
end

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

  ---@type ProjectDocument
  local project = renoise.Document.instantiate("LiveReloadProject")

  util.ensure_dir(project_dir)

  local xml_file_name = project_file_name(xrnx_id)

  if io.exists(xml_file_name) then
    ok, err = project:load_from(xml_file_name)

    if not ok then
      store.error_message.value = string.format("Error loading project XML: %s", err)
      return
    end
  else
    project.folder.value = path
    project.xrnx_id.value = xrnx_id
    project.build_command.value = util.detect_build_command(path, xrnx_id..".xrnx")

    save_project(project)
  end

  store.project = project
  store.preferences.active_project.value = path
end

---@param store Store
---@param value string
function action.set_build_command(store, value)
  if not store.project then return end
  store.project.build_command.value = util.str_trim(value)

  save_project(store.project)
end

---@param store Store
---@param value boolean
function action.set_watch(store, value)
  store.preferences.watch.value = value
end

---@param store Store
function action.clear_build_log(store)
  if not store.project then return end

  while store.project.build_log:size() > 0 do
    store.project.build_log:remove(1)
  end

  save_project(store.project)
end

---@param store Store
---@param msg string
function action.log(store, msg)
  local line = string.format("[%s] %s", os.date("%c"), msg)

  store.project.build_log:insert(line)
end

function action.sync_logs(store)
  while store.project.build_log:size() > 50 do
    store.project.build_log:remove(1)
  end
  save_project(store.project)
end

---@param store Store
function action.spawn_build(store)
  local log = function (msg) action.log(store, msg) end

  log("Starting build")

  local folder = store.project.folder.value
  local xrnx_id = store.project.xrnx_id.value
  local build_cmd = store.project.build_command.value

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
    local last_mtime = store.project.last_mtime.value
    store.project.last_mtime.value = stat.mtime
    save_project(store.project)
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