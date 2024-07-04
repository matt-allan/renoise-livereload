local action = require "action"
local bus = require "bus"
local store = require "store"
local task = require "task"
local view = require "view"

local IS_DEV = false

local function bind_handlers()
  for key,fn in pairs(action) do
    bus:subscribe(key, function (_message, ...)
      fn(store, ...)
    end)
  end
end

local function main()
  if IS_DEV then bus:subscribe("*", function (msg) print("MSG: "..msg) end) end
  bind_handlers()
  bus:publish("boot")
  task(store, bus)
  view(store, bus)
end

main()
