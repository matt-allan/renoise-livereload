local util = require "util"
local vb = renoise.ViewBuilder()
local tool = renoise.tool()
local app = renoise.app()

local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

---@param store Store
---@param bus Bus 
---@return renoise.Views.MultiLineTextField
local function build_command_view(store, bus)
  local view = vb:textfield {
    text = "",
    notifier = function (value)
      bus:publish("set_build_command", value)
    end,
    width = "100%",
  }

  local sync_build_command = function ()
    view.text = store.project and store.project.build_command.value or ""
  end

  store.preferences.active_project:add_notifier(function ()
    sync_build_command()
  end)

  sync_build_command()

  return view
end

---@param store Store
---@return renoise.Views.MultiLineTextField
local function build_log_view(store)
  local view = vb:multiline_text {
    width = "100%",
    height = 80,
    font = "mono",
    style = "border",
    text = "",
  }

  local sync_lines = function ()
    if not store.project then return end
    local lines = util.collect_observable_list(store.project.build_log)
    view.text = table.concat(lines, "\n")
    view:scroll_to_last_line()
  end
  store.preferences.active_project:add_notifier(function ()
    if not store.project.build_log:has_notifier(sync_lines) then
      store.project.build_log:add_notifier(sync_lines)
    end
    sync_lines()
  end)
  if store.project then
    store.project.build_log:add_notifier(sync_lines)
  end
  sync_lines()

  return view
end

---@param store Store
---@return renoise.Views.Text
local function active_project_view(store)
  local view = vb:text {
    text = store.preferences.active_project.value,
    width = "100%",
    style = "strong",
    font = "mono",
  }
  store.preferences.active_project:add_notifier(function ()
    view.text = store.preferences.active_project.value
  end)

  return view
end

---@param store Store
---@param bus Bus
---@return renoise.Views.Rack
local function build_dialog_view(store, bus)
  local build_config_group = vb:column {
    margin = DEFAULT_MARGIN,
    style = "group",
    uniform = true,
    width = "100%",
    vb:horizontal_aligner {
      mode = "justify",
      vb:column {
        width = "80%",
        spacing = DEFAULT_CONTROL_SPACING,
        vb:text {
          text = "Folder:",
        },
        active_project_view(store),
        vb:text {
          text = "Build command:",
          font = "mono",
        },
        build_command_view(store, bus),
        vb:row {
          vb:checkbox {
            value = store.preferences.watch.value,
            notifier = function (value)
              bus:publish("set_watch", value)
            end
          },
          vb:text { text = "Watch for changes" },
        },
      },
      vb:column {
        width = "10%",
        spacing = DEFAULT_CONTROL_SPACING,
        vb:space {
          height = DEFAULT_CONTROL_HEIGHT,
          width = "100%",
        },
        vb:button {
          text = "Browse",
          width = "100%",
          released = function ()
            local folder = app:prompt_for_path("Open project")

            if folder == "" then return end

            bus:publish("open_project", folder)
          end
        },
        vb:space {
          height = DEFAULT_CONTROL_HEIGHT,
          width = "100%",
        },
        vb:button {
          text = "Build",
          width = "100%",
          released = function ()
            if store.project then
              bus:publish("spawn_build")
            end
          end,
        },
      }
    },
  }

  local build_log_group = vb:column {
    margin = DEFAULT_MARGIN,
    style = "group",
    uniform = true,
    width = "100%",
    vb:text {
      text = "Build log:",
    },
    build_log_view(store),
    vb:button {
      text = "Clear",
      width = "10%",
      released = function ()
        bus:publish("clear_build_log")
      end
    },
  }

  return vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_MARGIN,
    uniform = true,
    width = 480,
    build_config_group,
    build_log_group,
  }
end

---@type renoise.Dialog?
local build_dialog = nil

---@param store Store
---@param bus Bus 
local function show_build_dialog(store, bus)
  if build_dialog and build_dialog.visible then
    build_dialog:show()
    return
  end

  local dialog_view = build_dialog_view(store, bus)

  build_dialog = app:show_custom_dialog(
    "Live Reload",
    dialog_view
  )
end

---@param entry ToolMenuEntry
local function add_menu_entry(entry)
  if tool:has_menu_entry(entry.name) then return end

  tool:add_menu_entry(entry)
end

local recent_entries = {}

---@param store Store
---@param bus Bus
local function build_menu(store, bus)
  add_menu_entry {
    name = "Main Menu:Tools:LiveReload:Open project...",
    invoke = function()
      local folder = app:prompt_for_path("Open project")

      if folder == "" then return end

      bus:publish("open_project", folder)
    end,
  }

  for i,entry_name in pairs(recent_entries) do
    if store.preferences.recent_projects[i] == nil then
      if tool:has_menu_entry(entry_name) then tool:remove_menu_entry(entry_name) end
    end
    recent_entries[i] = nil
  end
  for i=1,#store.preferences.recent_projects do
    local name = store.preferences.recent_projects[i].value
    local entry_name = "Main Menu:Tools:LiveReload:Open recent project...:" .. name
    add_menu_entry {
      name = entry_name,
      invoke = function()
        bus:publish("open_project", name)
      end,
    }
    recent_entries[i] = entry_name
  end

  add_menu_entry {
    name = "Main Menu:Tools:LiveReload:Open recent project...:Clear menu",
    invoke = function()
      bus:publish("clear_recent_projects")
    end,
  }

  add_menu_entry {
    name = "Main Menu:Tools:LiveReload:Settings...",
    invoke = function()
      if not store.preferences.active_project then
        local folder = app:prompt_for_path("Open project")
        if folder == "" then return end
        bus:publish("open_project", folder)
      end

      show_build_dialog(store, bus)
    end,
  }
end

---@param store Store
---@param bus Bus
local function view(store, bus)
  store.preferences.recent_projects:add_notifier(function ()
    build_menu(store, bus)
  end)

  store.preferences.active_project:add_notifier(function ()
    show_build_dialog(store, bus)
  end)

  store.error_message:add_notifier(function ()
    local message = store.error_message.value
    if message == "" then return end
    app:show_error(message)
    store.error_message.value = ""
  end)

  build_menu(store, bus)
  show_build_dialog(store, bus)
end

return view