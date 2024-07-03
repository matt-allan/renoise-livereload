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

--List all entries in a directory with the given extensions, recursively.
function util.listdir(dir, extensions)
  local paths = {}
  for _, filename in ipairs(os.filenames(dir, extensions)) do
      table.insert(paths, util.path_join(dir, filename))
  end

  for _, dirname in ipairs(os.dirnames(dir)) do
    for _, dirpath in ipairs(util.listdir(util.path_join(dir, dirname), extensions)) do
      table.insert(paths, dirpath)
    end
  end

  return paths
end

---Recursively stat every file in a directory.
---@param path string
---@param extensions string[]
---@return {mtime: integer, size: integer, file: string}[]?
---@return string?
function util.stat_dir(path, extensions)
  local files = util.listdir(path, extensions)

  local stats = {}

  for _,file in ipairs(files) do
    local stat, err, _code = io.stat(file)
    if stat == nil or err then
      return nil, err
    end

    table.insert(stats, {mtime = stat.mtime, size = stat.size, file = file})
  end

  return stats, nil
end


---@param stats StatEntry[]
---@return string
function util.stat_encode(stats)
  local lines = {}

  for _,stat in ipairs(stats) do
    local line = ""
    for k,v in pairs(stat) do
      if k ~= "file" then
        line = line .. string.format("%s=%d ", k, v)
      end
    end
    line = line .. stat.file
    table.insert(lines, line)
  end

  return table.concat(lines, "\n") .. "\n"
end

---@param data string
---@return StatEntry[]
function util.stat_decode(data)
  local stats = {}

  for line in string.gmatch(data, "(.-)\n") do
    local attrs = {}
    local i=1
    for k,v,pos in string.gmatch(line, "(%w+)=(%w+)()") do
      attrs[k] = v
      i=pos
    end
    local file = string.sub(line, i+2)
    local stat = {}
    for k,v in pairs(attrs) do
      stat[k] = tonumber(v)
    end
    stat.file = file
    table.insert(stats, stat)
  end

  return stats
end

---Diff the stat entries and return any changed or new files.
---@param old StatEntry[]
---@param new StatEntry[]
---@return string[]
function util.stat_diff(old, new)
  local old_files = {}
  for _,stat in ipairs(old) do
    old_files[stat.file] = stat
  end
  rprint(old_files)
  local changed = {}
  for _,stat in ipairs(new) do
    local old_stat = old_files[stat.file]
    if not old_stat then
      table.insert(changed, stat.file)
    else
      if stat.mtime ~= old_stat.mtime or stat.size ~= old_stat.size then
        table.insert(changed, stat.file)
      end
    end
  end

  return changed
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
