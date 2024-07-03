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
    error(string.format("Manifest not found at path %s", manifest_path))
  end

  local manifest_doc = renoise.Document.instantiate("RenoiseScriptingTool")

  local ok, err = manifest_doc:load_from(manifest_path)

  if not ok then
    error(string.format("Error loading manifest: %s", err))
  end

  local xrnx_id = manifest_doc["Id"].value

  if not xrnx_id then
    error("Manifest field 'Id' not found")
  end

  ---@type ProjectDocument
  local project = renoise.Document.instantiate("LiveReloadProject")

  util.ensure_dir(project_dir)

  local xml_file_name = project_file_name(xrnx_id)

  if io.exists(xml_file_name) then
    ok, err = project:load_from(xml_file_name)

    if not ok then
      error(string.format("Error loading project XML: %s", err))
    end
  else
    project.folder.value = path
    project.xrnx_id.value = xrnx_id
    project.build_command.value = util.detect_build_command(path, xrnx_id..".xrnx")
    project.file_extensions:insert(".lua")
    project.file_extensions:insert(".xml")

    save_project(project)
  end

  store.project = project
  store.preferences.active_project.value = path
  if not store.preferences.recent_projects:find(path) then
    store.preferences.recent_projects:insert(path)
  end

  if not store.preferences.build_dialog_opened.value then
    store.preferences.build_dialog_opened.value = true
  end
end

function action.clear_recent_projects(store)
  while #store.preferences.recent_projects > 0 do
    store.preferences.recent_projects:remove()
  end
end

---@param store Store
---@param value string
function action.set_build_command(store, value)
  store.project.build_command.value = util.str_trim(value)

  save_project(store.project)
end

---@param store Store
---@param value boolean
function action.toggle_watch(store, value)
  store.preferences.watch.value = value
end

---@param store Store
function action.clear_build_log(store)
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

  local stats, err = util.stat_dir(
    store.project.folder.value,
    util.collect_observable_list(store.project.file_extensions)
  )

  if not stats then
    log(string.format("ERROR: %s", err))
    return
  end

  local old_stats = util.stat_decode(store.project.statdb.value)
  print(string.format("%d old stats", #old_stats))
  print(string.format("%d new stats", #stats))
  local changed_files = util.stat_diff(old_stats, stats)
  -- rprint(changed_files)

  if #changed_files == 0 then
    log("No changes")
    return
  end
  log(string.format("Detected %s changed files", #changed_files))
  store.project.statdb.value = util.stat_encode(stats)
  save_project(store.project)

  local folder = store.project.folder.value
  local xrnx_id = store.project.xrnx_id.value
  local build_cmd = store.project.build_command.value

  log(string.format("Executing build command `%s`", build_cmd))
  local command = string.format(
    "cd %s && %s",
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

  log("Installing...")
  action.sync_logs(store)
  renoise.app():install_tool(xrnx_path)
end

return action