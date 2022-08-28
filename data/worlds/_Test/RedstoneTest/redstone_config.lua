local redAI = {}
local redstoneconfig = {}
local redstone = {}

expandedDefines = require("expandedDefines")

min, max, abs, clamp = math.min, math.max, math.abs, math.clamp
insert, map, unmap, append = table.insert, table.map, table.unmap, table.append
gmatch, find, sub = string.gmatch, string.find, string.sub

local blockConfigCache = {}
function configCacheBlock(id)
  if not blockConfigCache[id] then
    blockConfigCache[id] = Block.config[id]
  end

  return blockConfigCache[id]
end

function redAI.loadconfig(redstone)
  local component = redstone.component

  -- Set this to false and the script will no longer stop NPCs from despawning. This will reduce lag in your level! I reccomend you set this to false and install spawnzones into your level
  redstoneconfig.disabledespawn = false

  return redstoneconfig
end

function string.startswith(str, start)
  return str:sub(1, #start) == start
end

function string.endswith(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end


local function split(str, delim)
	local ret = {}
	if not str then
		return ret
	end
	if not delim or delim == '' then
		for c in gmatch(str, '.') do
			insert(ret, c)
		end
		return ret
	end
	local n = 1
	while true do
		local i, j = find(str, delim, n)
		if not i then break end
		insert(ret, sub(str, n, i - 1))
		n = j + 1
	end
	insert(ret, sub(str, n))
	return ret
end

local function getNameID(name)
  local id = ''
  for k, v in ipairs(split(name)) do
    if k > 7 and k < #name - 3 then
      if tonumber(v) then
        id = id..v
      else
        break
      end
    end
  end
  return tonumber(id)
end

local filepaths = {"", "../", "/RedstoneAI", "../RedstoneAI"}
local requirepaths = {"", "", "RedstoneAI/", "RedstoneAI/"}
function redAI.loadAI(redstone)
  local redfiles = {}

  for k, p in ipairs(filepaths) do
    for _, v in ipairs(Misc.listLocalFiles(p)) do
      if string.startswith(v, "rednpc-") and string.endswith(v, ".lua") then
        insert(redfiles, {p, requirepaths[k], v})
      end
    end
  end

  for k, v in ipairs(redfiles) do
    local path, name = v[2], v[3]
    local id = getNameID(name)
    if id then
      _G.NPC_ID = id
      local t = require(string.sub(path..name, 1, -5))
      redstone.registerNPC(id, t)
    else
      require(sub(path..name, 1, -5))
    end
  end
  _G.NPC_ID = nil
end

return redAI
