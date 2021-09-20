local save = {}

local serializer = require("ext/serializer")

save.data = {}
save.path = getSMBXPath().."/logs/_speedrun_settings.txt"
save.default = {
  showTimerClock = true,
  showTimerFrames = true,
  timerPosition = 2,
  timerSize = 1,
  showInputs = true,
  inputPosition = 3,
  printlog = false,
  showAttempts = true,
  attemptsPosition = 1,
  sectionsplit = 1,
  disableChecks = false,
  popout = false,
  enablesavestate = true,
  enableas = false,
  asCostume1 = 1,
  asCostume2 = 1,
  asBox1 = 0,
  asBox2 = 0,
  asHealth1 = 1,
  asHealth2 = 1
}

-- Basic array to string!
local function table2string(t)
  local s = "{"
  for k, v in pairs(t) do
    s = s..k.."="..tostring(v)..","
  end
  s = string.sub(s, 1, -2)
  s = "return "..s.."}"
  return s
end

local function strsplit(str, delim)
	local ret = {}
	if not str then
		return ret
	end
	if not delim or delim == '' then
		for c in string.gmatch(str, '.') do
			table.insert(ret, c)
		end
		return ret
	end
	local n = 1
	while true do
		local i, j = string.find(str, delim, n)
		if not i then break end
		table.insert(ret, string.sub(str, n, i - 1))
		n = j + 1
	end
	table.insert(ret, string.sub(str, n))
	return ret
end

local function string2table(s)
  local t = {}
  s = string.sub(s, 9, -2)
  local l = strsplit(s, ",")
  for k, v in ipairs(l) do
    local a = strsplit(v, "=")
    local key, value = a[1], a[2]
    if value == "true" then
      value = true
    elseif value == "false" then
      value = false
    else
      value = tonumber(value)
    end
    t[key] = value
  end
  return t
end

table2string = serializer.serialize
string2table = serializer.deserialize

local function dataValidation(t)
  for k, v in pairs(save.default) do
    if not t[k] then t[k] = v end
  end
  return t
end


function save.save()
  local writefile = io.open(save.path, "w")
  if not writefile then return end
  writefile:write(table2string(save.data))
  writefile:close()
end

function save.load()
  local file = io.open(save.path, "r") -- r read mode
  if not file then save.data = save.default return end
  local content = file:read("*all") -- *a or *all reads the whole file
  file:close()
  save.data = dataValidation(string2table(content))
end

-- Load settings!
save.load()

return save
