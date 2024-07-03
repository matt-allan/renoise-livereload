---@class Bus
local bus = {
  subscribers = {},
}

---@param message string
---@param ... any
function bus:publish(message, ...)
  for cb,_ in pairs(self.subscribers[message] or {}) do
    cb(message, ...)
  end

  for cb,_ in pairs(self.subscribers["*"] or {}) do
    cb(message, ...)
  end
end

---@param message string
---@param cb fun(message: string, ...)
---@return function unsubscribe
function bus:subscribe(message, cb)
  if self.subscribers[message] == nil then
    self.subscribers[message] = {}
  end

  self.subscribers[message][cb] = true

  return function ()
    self.subscribers[message][cb] = nil
  end
end

return bus