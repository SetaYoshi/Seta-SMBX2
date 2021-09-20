local npcAI = {}

local npcID = NPC_ID
local redstone = require("redstone")

-- vv Customization vv

-- List of NPCs ID this file will affect. This is for the walking birds NPCs
npcAI.birdist = {501, 502, 503, 504}

-- List of NPCs ID this file will affect. This is for the flying bird NPCs
npcAI.flybirdList = {505, 506, 507, 508}

-- ^^ Customization ^^

local birdMap = table.map(npcAI.birdist)
local flybirdMap = table.map(npcAI.flybirdList)

function npcAI.onRedPower(n, c, power, dir, hitbox)
  redstone.setEnergy(n, power)
end

function npcAI.onRedTick(n)
  local data = n.data
  data.observ = false

  if birdMap[n.id] then
    if data.power > 0 then
      n.id = n.id + 4
      n.speedY = -1
      n.dontMove = false
      n.direction = DIR_LEFT
      n.data._basegame.moveState = 3
      data.observ = true
    end
  elseif flybirdMap[n.id] then
    if not data.hasObserv then
      data.hasObserv = true
      data.observ = true
    end
  end

  redstone.resetPower(n)
end

for _, v in ipairs(table.append(npcAI.birdist, npcAI.flybirdList)) do
  redstone.registerNPC(v, npcAI)
end

return npcAI
