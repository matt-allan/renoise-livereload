local filepath = require "filepath"
local app = renoise.app()
local tool = renoise.tool()

-- Persistent settings and state for projects
renoise.Document.create("DevtoolsProject") {
  folder = "",
  id = "",
  build_command = "",
  files = {
    names = {""},
    mtimes = {0},
    sizes = {0},
  },
}
-- The Renoise xrnx manifest format
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

---@class Project
---@field folder string
---@field id string?
---@field build_command string?
local Project = {}
Project.__index = Project

function Project:new(folder)
  return setmetatable({
    folder = folder,
  }, Project)
end

---Load the project's manifest and configuration.
---@return boolean
---@return string
function Project:load()
  local manifest_path = filepath.join(self.folder, "manifest.xml")

  if not io.exists(manifest_path) then
    return false, "Manifest not found"
  end

  local manifest_doc = renoise.Document.instantiate("RenoiseScriptingTool")

  local ok, err = manifest_doc:load_from(manifest_path)

  if not ok then
    return false, "Error loading manifest: " .. err
  end

  local toolId = manifest_doc["Id"]

  if not toolId then
    return false, "Manifest Id not found"
  end

  self.id = toolId.value

  local project_doc = renoise.Document.instantiate("DevtoolsProject")
  local project_dir = filepath.join(tool.bundle_path, "Projects")
  if not io.exists(project_dir) then
    ok, err = os.mkdir(project_dir)
    if not ok then
      return false, "Error creating projects directory: " .. err
    end
  end
  local project_path = filepath.join(tool.bundle_path, "Projects", toolId.value) .. ".xml"

  if io.exists(project_path) then
    ok, err = project_doc:load_from(project_path)

    if not ok then
      return false, "Error loading project manifest: " .. err
    end

    -- TODO: Now assign stuff to the project that is set like files and build command
  else
    project_doc["folder"].value = self.folder
    project_doc["id"].value = toolId.value

    project_doc:save_as(project_path)
  end

  return true, ""
end

---@return string[]
local function listdir(dir, extensions)
  local paths = os.filenames(dir, extensions)

  for _, dirname in ipairs(os.dirnames(dir)) do
    for _, dirpath in ipairs(listdir(filepath.join(dir, dirname), extensions)) do
      table.insert(paths, filepath.join(dir, dirname, dirpath))
    end
  end

  return paths
end

---@return string[]
function Project:filenames()
  -- TODO: make configurable?
  return listdir(self.folder, {".lua", ".xml"})
end

function Project:build()
  if not self.id then
    error("Project manifest must be loaded before building")
  end

  if not self.build_command then
    --TODO: detect the command here
    -- A good default build command is:
    -- zip -vr <FILENAME>.xrnx * -x@../exclude.list
    self.build_command = "make"
  end

  app:show_status(string.format("Building %s...", self.id))

  local files = self:filenames()

  print(string.format("found %s files", #files))

  print("running "..self.build_command)
  local command = string.format("cd %s && %s", self.folder, self.build_command)
  local exit_code = os.execute(command)
  print(string.format("build finished with code %d", exit_code))

  local xrnx_path = filepath.join(self.folder, self.id)..".xrnx"

  if not io.exists(xrnx_path) then
    print("no xrnx generated?")
    app:show_error("Building the xrnx failed")
    return
  end

  app:show_status("")
  app:install_tool(xrnx_path)
end

return Project