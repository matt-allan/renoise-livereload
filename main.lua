local bus = require "bus"
local store = require "store"
local view = require "view"
local action = require "action"

local DEV = true

local function bind_handlers()
  for key,fn in pairs(action) do
    bus:subscribe(key, function (_message, ...)
      fn(store, ...)
    end)
  end
end

local function main()
  if DEV then bus:subscribe("*", function (msg) print("MSG: "..msg) end) end
  bind_handlers()
  bus:publish("boot")
  view(store, bus)
end

main()
