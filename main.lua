require "xml_doc" -- for side effects

local Store = require "store"
local task = require "task"
local view = require "view"

local function main()
  local store = Store:new()
  task(store)
  view(store)
end

main()
