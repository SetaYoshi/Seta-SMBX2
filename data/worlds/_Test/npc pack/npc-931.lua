local source = {}

-- lightbounce.lua v1.0
-- Created by SetaYoshi

local npcManager = require("npcManager")
local textplus = require("textplus")
local npcutils = require("npcs/npcutils")

local reset = false
local rays = {}
local npcID = NPC_ID

local config = npcManager.setNpcSettings({
	id = npcID,
	gfxwidth = 32,
	gfxheight = 32,
	gfxoffsetx = 0,
	gfxoffsety = 2,
	width = 32,
	height = 32,
	nogravity = false,
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	noblockcollision = false,
	playerblock = true,
	playerblocktop = true,
	npcblock = true,
	npcblocktop = true,
	speed = 1,
	foreground = 0,
	jumphurt = true,
	nohurt = true,
	score = 0,
	noiceball = true,
	nowaterphysics = false,
	foreground = true,
	noyoshi = false,
	grabtop=true,
	grabside = true,
	harmlessgrab = true,
	harmlessthrown = true,
	ignorethrownnpcs = true,

	reflector = 932,
	refractor = 933,
	absorber = 934
})
npcManager.registerHarmTypes(npcID, {HARM_TYPE_JUMP, HARM_TYPE_SPINJUMP}, {[HARM_TYPE_JUMP] = 10, [HARM_TYPE_SPINJUMP] = 10})

local colorlist = {Color.white, Color.red, Color(1, 0.42, 0), Color.yellow, Color.green, Color.blue,  Color.purple}
local function iniCheck(n)
	if n.direction == 0 then n.direction = RNG.irandomEntry({-1, 1}) end
	local data = n.data
	if not data.check then
		data.check = true
		data.color = data._settings.color
		data.angle = -90 - data._settings.angle
		data.color = colorlist[data.color + 1]
	end
end

local maxdist = 1000
local function createray(start, r, color, x, blacklist)
	if x <= 0 then return end
	local max = start + r*maxdist
	local stop = max

	local iscollision, point, normal, crashcollider
	local center = start + r*maxdist*0.5
	local lightcollider = Colliders.Rect(center.x, center.y, 4, maxdist, 90-math.deg(math.atan2(-r.y, r.x)))
	-- local n = r:rotate(90)
	-- local N = 2*n
	-- local z1, z2, z3, z4 = start + N, start - N, max + N, max - N
	-- local npcList = NPC.get(config.reflector)
	local npcList = Colliders.getColliding{a = lightcollider, b = {config.reflector, config.refractor, config.absorber}, btype = Colliders.NPC, filter = function(v) return v.data.collision end}
	local blockList = Colliders.getColliding{a = lightcollider, b = Colliders.BLOCK_SOLID..Colliders.BLOCK_LAVA..Colliders.BLOCK_HURT, btype = Colliders.BLOCK, filter = function(v) return v end}

	local currc

	if npcList[1] or blockList[1] then
		local collisionlist = {}
		for i = 1, #npcList do
			local c = npcList[i].data.collision
			if c and c ~= blacklist then table.insert(collisionlist, c) end
		end
		for i = 1, #blockList do
			table.insert(collisionlist, blockList[i])
		end
		if collisionlist[1] then
			iscollision, point, normal, crashcollider = Colliders.linecast(start, max, collisionlist)

			if iscollision then
				if not crashcollider then
					iscollision = false
					stop = point
				elseif crashcollider.typemydata == "reflector" and math.abs(normal..crashcollider.normalmydata) < 0.001 then
					stop = point
				elseif crashcollider.typemydata == "refractor" then
					stop = table.clone(point)
					local cx, cy = crashcollider.x + crashcollider.width*0.5, crashcollider.y + crashcollider.height*0.5
					local dx, dy = point.x - cx, point.y - cy
					point.x, point.y = point.x - 2*dx, point.y - 2*dy
					table.insert(rays, table.clone({start = stop, stop = point, color = Color.white}))
				elseif crashcollider.typemydata == "absorber" and (color == Color.white or crashcollider.colormydata == Color.white or crashcollider.colormydata == color) then
					iscollision = false
					stop = point
					crashcollider.hitmydata = true
				else
					iscollision = false
					stop = point
				end
			end
		end
		if iscollision then
			currc = crashcollider
		end
	end

	table.insert(rays, table.clone({start = start, stop = stop, color = color}))

	if iscollision then
		if crashcollider.typemydata == "reflector" then
			local bounce = -2*(r .. normal)*normal + r
			createray(point, bounce, color, x - 1, currc)
		else
			createray(point, r, crashcollider.colormydata, x - 1, currc)
		end
	end
end


function source.onTickNPC(n)
	local data = n.data
	iniCheck(n)

  if reset then
		reset = false
		rays = {}
	end

	if n.collidesBlockBottom then
		n.speedX = n.speedX*0.5
	end

	local v = vector.v2(n.x + 0.5*n.width, n.y + 0.5*n.height)
	local r = vector.v2(0, 1):rotate(n.direction*data.angle)
	createray(v, r, data.color, 80)
end

function source.onDraw()
	local p = -45
	if config.foreground then
		p = -15
	end
	for i = #rays, 1, -1 do
		local ray = rays[i]
		if ray.start and ray.stop then
			local start = ray.start
			local stop = ray.stop
			local color = ray.color

			local n = ((start - stop):normalize()):rotate(90)*2
			local z1, z2, z3, z4 = start + n, start - n, stop + n, stop - n
			Graphics.glDraw{vertexCoords = {z1.x, z1.y, z2.x, z2.y, z4.x, z4.y, z1.x, z1.y, z3.x, z3.y, z4.x, z4.y}, priority = p - 0.01, sceneCoords = true, color = {color.r, color.g, color.b, 0.8}}
		end
	end
	reset = true
end


function source.onInitAPI()
	npcManager.registerEvent(npcID, source, "onTickNPC", "onTickNPC")
	-- npcManager.registerEvent(npcID, source, "onDrawNPC", "onDrawNPC")
	registerEvent(source, "onDraw", "onDraw")
end

return source
