local reflector = {}
local npcManager = require("npcManager")
local rng = require("rng")
local lineguide = require("lineguide")
local utils = require("npcs/npcutils")

local npcID = NPC_ID
local config = npcManager.setNpcSettings{
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	width = 32,
	height = 32,
	frames = 1,
	framespeed = 8,
	framestyle = 0,
	score = 0,
	blocknpctop = false,
	playerblocktop = false,
	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	spinjumpsafe = false,
	jumphurt = true,
	ignorethrownnpcs = true,
	notcointransformable = true,
	staticdirection = true,
}
lineguide.registerNpcs(npcID)

local function updateSizeCache(npc, data)
	local img = Graphics.sprites.npc[npc.id].img
	data.gfxwidth = npc:mem(0xC0, FIELD_DFLOAT)
	data.gfxheight = npc:mem(0xB8, FIELD_DFLOAT)
	data.width = npc.width
	data.height = npc.height
	data.imgwidth = img.width
	data.imgheight = img.height
end

local function dataCheck(npc)
	local data = npc.data
	local img = Graphics.sprites.npc[npc.id].img

	if data.sprite == nil then
		local settings = npc.data._settings

		local w, h = utils.gfxwidth(npc), utils.gfxheight(npc)
		data.sprite = Sprite{x = npc.x, y = npc.y, width = w, height = h, texture = Graphics.sprites.npc[npcID].img, pivot = Sprite.align.CENTER}
		data.sprite.texscale = vector(img.width, img.height)
		data.angle = -npc.data._settings.angle
		data.collision = Colliders.Rect(npc.x + 0.5*npc.width, npc.y + 0.5*npc.height, 8, h, data.angle)
		data.collision.normalmydata = vector.v2(1, 0):rotate(90+data.angle)
		data.collision.typemydata = "reflector"
	else
		if data.gfxwidth ~= npc:mem(0xC0, FIELD_DFLOAT) or data.gfxheight ~= npc:mem(0xB8, FIELD_DFLOAT) or (data.gfxwidth == 0 and data.width ~= npc.width) or (data.gfxheight == 0 and data.height ~= npc.height) then
			data.sprite.width, data.sprite.height = getGFXSize(npc)
		end

		if data.imgwidth ~= img.width or data.imgheight ~= img.height then
			data.sprite.texscale = vector(img.width, img.height)
		end
	end

	updateSizeCache(npc,data)
end

function reflector.onTickNPC(npc)
	if Defines.levelFreeze or npc:mem(0x12A, FIELD_WORD) <= 0 or (npc.layerObj and npc.layerObj.isHidden) then return end
	-- if Defines.levelFreeze  or npc:mem(0x12A, FIELD_WORD) <= 0 or npc:mem(0x12C, FIELD_WORD) ~= 0 or npc:mem(0x138, FIELD_WORD) ~= 0 then return end
	dataCheck(npc)

	utils.applyLayerMovement(npc)

	if npc:mem(0x136, FIELD_BOOL) then
		npc.speedX = 0
		npc.speedY = 0
		return
	end

	local data = npc.data
	local config = reflector.config
	local settings = npc.data._settings
	local sprite = data.sprite

	sprite.rotation = data.angle
end

function reflector.onDrawNPC(npc)
	local data = npc.data
	if npc:mem(0x12A, FIELD_WORD) <= 0 or not data.sprite then return end
  local sprite = data.sprite

	sprite.x = npc.x + npc.width*0.5 + config.gfxoffsetx
	sprite.y = npc.y + npc.height*0.5 + config.gfxoffsety
	local p = -45
	if config.foreground then
			p = -15
	end

local y = sprite.texposition.y
sprite.texposition.y = y - utils.gfxheight(npc)*npc.animationFrame
sprite:draw{priority = p, sceneCoords = true}
sprite.texposition.y = y
utils.hideNPC(npc)
end

function reflector.onInitAPI()
	npcManager.registerEvent(npcID, reflector, "onTickNPC")
	npcManager.registerEvent(npcID, reflector, "onDrawNPC")
end

return reflector
