local util = require "util"

local stats = {
  {mtime=1718335994, size=5994, file="/Users/matt/Code/renoise-exs24/bytes.lua"},
  {mtime=1718335994, size=782, file="/Users/matt/Code/renoise-exs24/exsdump.lua"},
}

local data = util.stat_encode(stats)

print("Encoded: \n")
print(data)

local decoded = util.stat_decode(data)

print("Decoded: \n")
for _,stat in ipairs(decoded) do
  for k,v in pairs(stat) do
    if k ~= "file" then
      io.write(string.format("%s=%d ", k, v))
    end
  end
  print(stat.file)
end