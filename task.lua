local tool = renoise.tool()

---@param store Store
local function setup_watcher(store)
  local should_watch = function ()
    return store.watch and store.folder ~= ""
  end

  local trigger_build = function ()
    if should_watch() then
      store:spawn_build()
    end
  end

  store:watch_effect(function ()
    local has_notifier = tool.app_became_active_observable:has_notifier(trigger_build)
    if should_watch() then
      if not has_notifier then tool.app_became_active_observable:add_notifier(trigger_build) end
    else
      if has_notifier then tool.app_became_active_observable:remove_notifier(trigger_build) end
    end
  end)
end

---@param store Store
local function task(store)
  setup_watcher(store)
end

return task