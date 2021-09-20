local npcAI = {}

local redstone = require("redstone")
local npcID = NPC_ID

-- vv Customization vv

-- List of NPCs ID this file will affect
npcAI.booList = {38, 43, 44}

-- ^^ Customization ^^


function npcAI.onRedPower(n, c, power, dir, hitbox)
  return true
end

function npcAI.prime(n)
  local data = n.data

  data.redarea = data.redarea or redstone.basicRedArea(n)
  data.redhitbox = data.redhitbox or redstone.basicRedHitBox(n)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if n.ai1 == 0 then
    redstone.updateRedArea(n)
    redstone.updateRedHitBox(n)
    redstone.passEnergy{source = n, power = 15, hitbox = data.redhitbox, area = data.redarea}
  end

  if n.ai1 ~= data.prevAI then
    data.observ = true
  end

  data.prevAI = n.ai1
end

for _, v in ipairs(npcAI.booList) do
  redstone.registerNPC(v, npcAI)
end

return npcAI
