local Store = require "store"
local task = require "task"
local view = require "view"
local xml = require "xml"

local function main()
  xml.init()
  local store = Store:new()
  task(store)
  view(store)
end

main()
