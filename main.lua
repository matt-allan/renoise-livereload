require "xml_doc" -- for side effects

local store = require "store"
local task = require "task"
local view = require "view"

local function main()
  task(store)
  view(store)
end

main()
