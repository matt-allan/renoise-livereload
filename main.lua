local filepath = require "crater.filepath"
local Project = require "project"
local app = renoise.app()
local tool = renoise.tool()

local preferences = renoise.Document.create("Preferences") {
  active_project = "",
 }
 tool.preferences = preferences

---@type Project?
local active_project = nil

local function restore_project()
  local folder = preferences.active_project.value
  if not folder then return end

  local project = Project:new(folder)

  local ok, err = project:load()

  if not ok then
    preferences.active_project.value = nil
    app:show_error(err)
    return
  end

  active_project = project
end

restore_project()

local function rebuild()
  if not active_project then return end

  active_project:build()
end

if not tool.app_became_active_observable:has_notifier(rebuild) then
  tool.app_became_active_observable:add_notifier(rebuild)
end

tool:add_menu_entry {
  name = "Main Menu:Tools:Devtools:Open...",
  invoke = function()
    local folder = app:prompt_for_path("Open project")

    if folder == "" then
      return
    end

    local project = Project:new(folder)

    local ok, err = project:load()
    if not ok then
      app:show_error(err)
      return
    end

    preferences.active_project.value = project.folder
    active_project = project
    project:build()
  end
}

-- TODO: Add menus like these for all recent projects
tool:add_menu_entry {
  name = "Main Menu:Tools:Devtools:Open Recent:Example",
  invoke = function()
  end
}

tool:add_menu_entry {
  name = "Main Menu:Tools:Devtools:Build...",
  invoke = function()
    -- TODO
    -- Shows log output
    -- Allows changing settings (?)
    -- Button force rebuild
    -- Need to remember if this is open
  end,
}

-- tool:add_menu_entry {
--   name = "Main Menu:Tools:Devtools:",
--   invoke = function()
--     -- TODO
--     -- Need to remember if this is open
--   end,
-- }