local util = require "util"

local build = {}

---@param root_path string
---@return ToolManifestDocument?
---@return string
local function load_manifest(root_path)
  local manifest_path = util.path_join(root_path, "manifest.xml")

  if not io.exists(manifest_path) then
    return nil, string.format("Manifest not found at path %s", manifest_path)
  end

  ---@type ToolManifestDocument
  local doc = renoise.Document.instantiate("RenoiseScriptingTool")

  local ok, err = doc:load_from(manifest_path)

  if not ok then
    return nil, string.format("Error loading manifest: %s", err)
  end

  return doc, ""
end

---@param store Store
---@param path string?
function build.open(store, path)
  path = path or store.folder
  if not path or path == "" then return end

  local manifest, err = load_manifest(path)

  if not manifest then
    store.error_message = err
    return
  end

  if not manifest["Id"] then
    store.error_message = "Manifest field 'Id' not found"
    return
  end

  local xrnx_id = manifest["Id"].value

  store:set_workspace({
    path = path,
    xrnx_id = xrnx_id,
    build_command = build.detect_build_command(path, xrnx_id..".xrnx"),
  })
end

---@param path string
---@param outfile string
---@return string
function build.detect_build_command(path, outfile)
  if io.exists(util.path_join(path, "Makefile")) then
    return "make"
  end

  local cmd = string.format("zip -vr %s *", outfile)

  if io.exists(util.path_join(path, "exclude.list")) then
    cmd = cmd .. "-x@../exclude.list"
  end

  return cmd
end

---@param store Store
function build.spawn(store)
  local log = function (msg)
    local line = string.format("[%s] %s", os.date("%c"), msg)
    store:log(line)
  end

  local workspace = store:workspace()

  log("Starting build")

  log("==> "..string.format("$ %s", workspace.build_command))

  local output, exit_code, err = util.shell_exec(workspace.path, workspace.build_command)

  if not output then
  log(string.format("ERROR: Exec error: '%s'", err))
  return
  end

  for _,line in ipairs(output) do
    log("==> "..line)
  end

  if exit_code ~= 0 then
    log(string.format("ERROR: Build failed with exit code %d", exit_code))
    return
  end

  local xrnx_path = util.path_join(workspace.path, workspace.xrnx_id)..".xrnx"

  if not io.exists(xrnx_path) then
    log("ERROR: No xrnx generated")
    return
  end

  local stat, stat_err = io.stat(xrnx_path)

  if not stat then
    log(string.format("ERROR: Stat error: '%s'", stat_err))
    return
  end

  local last_mtime = store:swap_mtime(stat.mtime)
  if stat.mtime == last_mtime then
    log("No changes")
    return
  end

  log(string.format("Installing %s.xrnx", workspace.xrnx_id))

  renoise.app():install_tool(xrnx_path)
end

return build