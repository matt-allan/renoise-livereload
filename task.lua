local action = require "action"
local tool = renoise.tool()

---@param store Store
local function setup_watcher(store)
  local should_watch = function ()
    return store.preferences.watch.value and store.project ~= nil
  end

  local trigger_build = function ()
    if should_watch() then
      action.spawn_build(store)
    end
  end

  local update_bindings = function ()
    local has_notifier = tool.app_became_active_observable:has_notifier(trigger_build)
    if should_watch() then
      if not has_notifier then tool.app_became_active_observable:add_notifier(trigger_build) end
    else
      if has_notifier then tool.app_became_active_observable:remove_notifier(trigger_build) end
    end
  end

  store.preferences.watch:add_notifier(update_bindings)
  store.preferences.active_project:add_notifier(update_bindings)
  update_bindings()
end

---@param store Store
local function task(store)
  setup_watcher(store)
end

return task