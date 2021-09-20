local npcAI = {}

-- vv Customization vv

local shellList = {5, 7, 73, 24, 172, 174, 113, 114, 115, 116}

-- ^^ Customization ^^

local npcID = NPC_ID
local redstone = require("redstone")

function npcAI.onDispense(n)
  n.speedX = 7.1*n.direction
end

for _, v in ipairs(shellList) do
  redstone.registerNPC(v, npcAI)
end

return npcAI
