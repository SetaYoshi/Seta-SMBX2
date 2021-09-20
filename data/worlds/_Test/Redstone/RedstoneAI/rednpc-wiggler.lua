local npcAI = {}

local redstone = require("redstone")
local npcID = NPC_ID

-- vv Customization vv

-- List of NPCs ID this file will affect
npcAI.wigglerList = {446, 448}

-- ^^ Customization ^^


function npcAI.prime(n)
  local data = n.data
  data.wasAngry = data._basegame.isAngry
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 and not data._basegame.isAngry then
    data._basegame.turningAngry = true
    SFX.play(9)
  end

  if data._basegame.isAngry ~= data.wasAngry then
    data.observ = true
  end

  data.wasAngry = data._basegame.isAngry
  redstone.resetPower(n)
end

for _, v in ipairs(npcAI.wigglerList) do
  redstone.registerNPC(v, npcAI)
end

return npcAI
