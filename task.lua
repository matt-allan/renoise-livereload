local tool = renoise.tool()

---@param store Store
---@param bus Bus
local function setup_watcher(store, bus)
  local should_watch = function ()
    return store.preferences.watch.value and store.project ~= nil
  end

  local trigger_build = function ()
    if should_watch() then
      bus:publish("spawn_build")
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
---@param bus Bus
local function task(store, bus)
  setup_watcher(store, bus)
end

return task