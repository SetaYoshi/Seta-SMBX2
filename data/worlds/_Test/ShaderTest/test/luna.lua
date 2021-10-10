local click = require("click")

local capture = Graphics.CaptureBuffer(800,600)

local invsShader = Shader()
invsShader:compileFromFile(nil, Misc.resolveFile("inverseZones.frag"))

local ringShader = Shader()
ringShader:compileFromFile(nil, Misc.resolveFile("playerRing.frag"))

local outline = {}
for i = 0, 360 do
  outline[i] = 0
end

local nRings = 5
local aRings = 32
local radius = 0
function onTick()
  radius = (vector(click.sceneX, click.sceneY) - vector(player.x, player.y)).length
  for i = 0, 360 do
    outline[i] = aRings*math.sin(math.rad(i + lunatime.tick()%360)*nRings)
  end
end

function onDraw()
  local zones = {}

  capture:captureAt(-40)
  for k, v in ipairs(NPC.getIntersecting(camera.x, camera.y, camera.x + camera.width, camera.y + camera.height)) do
    local z1 = vector((v.x - camera.x)/800, (v.y - camera.y)/600)
    local zw, zh = vector(v.width/800, 0), vector(0, v.height/600)
    local z2, z3, z4 = z1 + zw, z1 + zw + zh, z1 + zh

    local textureCoords = {z1.x, z1.y, z2.x, z2.y, z3.x, z3.y, z4.x, z4.y} --thanks mda
    Graphics.drawBox{sceneCoords = true, x = v.x, y = v.y, width = v.width, height = v.height, texture = capture, textureCoords = textureCoords, priority = -39, shader = invsShader}
  end

  capture:captureAt(0)
  Graphics.drawScreen{texture = capture, priority = 0, shader = ringShader, uniforms = {center = {player.x + 0.5*player.width - camera.x, player.y + 0.5*player.height - camera.y}, outline = outline, radius = radius}}
end
