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

function util.str_trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function util.str_limit(s, len)
  if #s <= len then return s end
  return string.sub(s, 1, len) .. "..."
end

---@param folder string
---@param cmd string
---@return string[]?
---@return number
---@return string?
function util.shell_exec(folder, cmd)
  assert(folder and #folder > 1)
  assert(cmd and #cmd > 1)

  local sh_cmd = string.format(
    "cd %q && %s 2>&1; echo %s",
    folder,
    cmd,
    os.platform() == "WINDOWS" and "$LastExitCode" or "$?"
  )

  local fh, err = io.popen(sh_cmd)

  if not fh then
    return nil, -1, err
  end

  local output = {}
  for line in fh:lines() do
    table.insert(output, line)
  end
  local exit_code = table.remove(output)

  return output, tonumber(exit_code) or 0, ""
end

return util
