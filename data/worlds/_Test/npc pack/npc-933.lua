local refractor = {}

local npcManager = require("npcManager")

local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 64,
	width = 32,
	height = 32,
	gfxoffsety = 32,
	speed = 1,
	frames = 1,
	framespeed = 4,
	framestyle = 0,
	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = true,
	noyoshi=true,
	grabside = false,
	harmlessthrown=false,
	noiceball=true,
	nofireball=true,
	nogravity = true,
	respawn = 150
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_EXT_FIRE, HARM_TYPE_EXT_ICE, HARM_TYPE_EXT_HAMMER})

local colorlist = {Color.white, Color.red, Color(1, 0.42, 0), Color.yellow, Color.green, Color.blue,  Color.purple}
local iniNPC = function(n)
  local data = n.data
  if not data.check then
		data.check = true
		data.color = data._settings.color
		data.color = colorlist[data.color + 1]
		data.collision = Colliders.Box(n.x, n.y, n.width, n.height)
		data.collision.typemydata = "refractor"
		data.collision.colormydata = data.color
	end
end

function refractor.onTickNPC(n)
	iniNPC(n)
end
-- refractor.onDrawNPC = balls.onDrawNPC

function refractor.onInitAPI()
  npcManager.registerEvent(npcID, refractor, "onTickNPC")
	npcManager.registerEvent(npcID, refractor, "onDrawNPC")
end

return refractor
