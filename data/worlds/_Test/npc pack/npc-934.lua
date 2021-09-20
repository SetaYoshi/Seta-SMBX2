local refractor = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	gfxoffsety = 0,
	speed = 1,
	frames = 2,
	framespeed = 4,
	framestyle = 0,
	score = 0,
	jumphurt = true,
	spinjumpsafe = false,
	nohurt = true,
	noyoshi=true,
	grabside = false,
	harmlessthrown=false,
	noiceball=false,
	nofireball=false,
	nogravity = true,
	darkframes = 1,
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_NPC, HARM_TYPE_PROJECTILE_USED, HARM_TYPE_EXT_FIRE, HARM_TYPE_EXT_ICE, HARM_TYPE_EXT_HAMMER})

local colorlist = {Color.white, Color.red, Color(1, 0.42, 0), Color.yellow, Color.green, Color.blue,  Color.purple}
local iniNPC = function(n)
  local data = n.data
  if not data.check then
		data.check = true
		data.color = data._settings.color
		data.color = colorlist[data.color + 1]
		data.collision = Colliders.Circle(n.x + 0.5*n.width, n.y + 0.5*n.height, n.width*0.5)
		data.collision.typemydata = "absorber"
		data.collision.colormydata = data.color
	end
end

function refractor.onTickNPC(n)
	iniNPC(n)
end
function refractor.onDrawNPC(n)
	local frames = config.frames - config.darkframes
	local offset = 0
	local gap = config.darkframes
	if not n.data.collision.hitmydata then
		n.animationFrame = -99
		Graphics.drawBox{x = n.x, y = n.y, width = n.width, height = n.height, texture = Graphics.sprites.npc[npcID].img, color = n.data.color, sceneCoords = true, textureCoords = {0, 0, 0, 0.5, 1, 0.5, 1, 0}}
	else
		n.data.collision.hitmydata = false
		frames = config.darkframes
		offset = config.frames - config.darkframes
		gap = 0
	end
	--npcutils.restoreAnimation(coin)
	n.animationFrame = npcutils.getFrameByFramestyle(n, { frames = frames, offset = offset, gap = gap })

end
-- refractor.onDrawNPC = balls.onDrawNPC

function refractor.onInitAPI()
  npcManager.registerEvent(npcID, refractor, "onTickNPC")
	npcManager.registerEvent(npcID, refractor, "onDrawNPC")
end

return refractor
