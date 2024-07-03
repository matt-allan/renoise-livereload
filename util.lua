local DIR_SEP = package.config:sub(1,1)
local DIR_SEPB = string.byte(DIR_SEP)

local util = {}

-- Join path segments with a director separator
function util.path_join(p, ...)
  for _,s in ipairs({...}) do
    if string.byte(p, -1) ~= DIR_SEPB then
      p = p .. DIR_SEP
    end
    p = p .. s
  end

  return p
end

function util.ensure_dir(path)
  if not io.exists(path) then
    local ok, err = os.mkdir(path)
    if not ok then
      error(string.format("Error creating directory at %s: %s", path, err))
    end
  end
end

function util.detect_build_command(path, outfile)
  if io.exists(util.path_join(path, "Makefile")) then
    return "make"
  end

  local cmd = string.format("zip -vr %s *", outfile)

  if io.exists(util.path_join(path, "exclude.list")) then
    cmd = cmd .. "-x@../exclude.list"
  end

  return cmd
end

function util.str_trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function util.str_limit(s, len)
  if #s <= len then return s end
  return string.sub(s, 1, len) .. "..."
end

---Collect the values from an observable list into a table.
---@param list renoise.Document.ObservableList
---@return table
function util.collect_observable_list(list)
  local t = {}
  for i=1,#list do
    table.insert(t, list[i].value)
  end
  return t
end

return util
