local npcAI = {}

-- vv Customization vv

-- List of NPCs ID this file will affect
npcAI.donutList = {46, 212}

-- ^^ Customization ^^

local npcID = NPC_ID
local redstone = require("redstone")

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if data.power > 0 then
    n.ai1 = 1
    n.ai3 = 30
  end

  if n.ai1 == 1 and data.prevAI ~= 1 then
    data.observ = true
  end

  data.prevAI = n.ai1
  redstone.resetPower(n)
end

for _, v in ipairs(npcAI.donutList) do
  redstone.registerNPC(v, npcAI)
end

return npcAI
