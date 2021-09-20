local lib = {}

local PATH = getSMBXPath().."\\worlds\\_Speedrunner\\"
local textplus = require("textplus")
local playerManager = require("playerManager")
local textfont = textplus.loadFont("textplus/font/6.ini")


local function formatTime(t, h)
	realMiliseconds = math.floor(t*15.6)
	miliseconds = realMiliseconds%1000
	realSeconds = math.floor(realMiliseconds/1000)
	seconds = realSeconds%60
	realMinutes = math.floor(realSeconds/60)
	minutes = realMinutes%60
	hours = math.floor(realMinutes/60)
	if hours < 10 then hours = "0"..tostring(hours)	end
  if minutes < 10 then minutes = "0"..tostring(minutes)	end
	if seconds < 10 then seconds = "0"..tostring(seconds)	end
	if miliseconds < 10 then miliseconds = "00"..tostring(miliseconds)
	elseif miliseconds < 100 then	miliseconds = "0"..tostring(miliseconds) end

  if hours ~= "00" then
    return table.concat({hours, minutes, seconds, miliseconds}, ":")
  elseif minutes ~= "00" or h then
    return table.concat({minutes, seconds, miliseconds}, ":")
  else
    return table.concat({seconds, miliseconds}, ":")
  end
end

-- Reset timer when an episode run begins
if GameData._speedrunner_prevsavefile ~= Misc.saveSlot() or GameData._speedrunner_prevepisodepath ~= Misc.episodePath() then
	GameData._speedrunner_etimer = nil
	GameData._speedrunner_log = nil
end
GameData._speedrunner_prevepisodepath = Misc.episodePath()
GameData._speedrunner_prevsavefile = Misc.saveSlot()

GameData._speedrunner_etimer = GameData._speedrunner_etimer or 0
GameData._speedrunner_log = GameData._speedrunner_log or {}


local iIcons = Graphics.loadImage(PATH.."icons.png")
local iStat = Graphics.loadImage(PATH.."stat.png")

-- Set up settings
local settingsLib = require(PATH.."settings.lua")
local settings = settingsLib.data

local worldstatLib = require(PATH.."worldstat.lua")
local worldstat = worldstatLib.data

local timerX = {8, 400, 792}
local timerXSplit = {8, 200, 396}
local timerPivot = {vector(0, 1), vector(0.5, 1), vector(1, 1)}
local timerSize = {1, 2, 2.5}

local iInputs = Graphics.loadImage(PATH.."inputs.png")
local pList = {player, player2}
local keyname = {"left", "up", "down", "right", "jump", "altJump", "run", "altRun", "pause", "dropItem"}
local inputX = {8, 310, 612}
local inputXSplit = {8, 110, 212}

-- Input manager for menu
local commander = require(PATH.."mycommander.lua")
commander.register{{menu = 192, delete = 46, back = {name = "run"}, select = {name = "jump"}, up = {name = "up"},  down = {name = "down"}, left = {name = "left"}, right = {name = "right"}}}
-- 192 is the tilde key
-- 46 is the delete key

-- Load the menu library and pass important data
local menu = require(PATH.."mymenu.lua")
menu.data = settings
menu.input = commander[1]
menu.save = settingsLib.save

menu.aScroll = Audio.SfxOpen(PATH.."scroll.ogg")
menu.aOpen = Audio.SfxOpen(PATH.."open.ogg")
menu.aClose = Audio.SfxOpen(PATH.."close.ogg")
menu.aSelect = Audio.SfxOpen(PATH.."select.ogg")

local finTypes = {
  [1]  = "Roulette",
  [2]  = "? Orb",
  [3]  = "Keyhole",
  [4]  = "Crystal Orb",
  [5]  = "Game End",
  [6]  = "Star",
  [7]  = "Goal Tape",
  [8]  = "Offscreen Exit",
  [9]  = "Warp Exit",
	[10] = "Custom Game End"
}


local charNameList = {}
local costumelist = {"NONE"}
for k, v in pairs(playerManager.getCharacters()) do
  charNameList[k] = v.name
	for _, c in ipairs(playerManager.getCostumes(k)) do
	table.insert(costumelist, c)
end
end
local function getCharName(id)
  local s = charNameList[id]
  if s then return s end
  return "Unknown"
end

local function getCostumeName(name)
  if not name then return "None" end
  return name
end

local powNameList = {"Small", "Mushroom", "Fire Flower", "Super Leaf", "Tanooki Suit", "Hammer Suit", "Ice Flower"}
local function getPowName(id)
  local s = powNameList[id]
  if s then return s end
  return "Unknown"
end

local mountNameList = {"None", "Goomba Shoe", "Podoboo Shoe", "Lakitu Shoe", "Green Yoshi", "Blue Yoshi", "Yellow Yoshi", "Red Yoshi", "Black Yoshi", "Purple Yoshi", "Pink Yoshi", "Cyan Yoshi", "Clown Car"}
local function getMountName(type, color)
  if type == 0 then
    return mountNameList[1]
  elseif type == 1 then
    return mountNameList[1 + color]
  elseif type == 2 then
    return mountNameList[4 + color]
  elseif type == 3 then
    return mountNameList[12]
  end
  return "Unknown"
end

local boxNameList = {[9] = "Mushroom", [14] = "Fire Flower", [22] = "Billy Gun", [26] = "Spring", [29] = "Hammer Bro.", [31] = "Key", [32] = "P-Switch", [34] = "Super Left", [35] = "Goomba Shoe", [49] = "Ptooie", [56] = "Koopa Clown Car", [95] = "Green Yoshi", [98] = "Blue Yoshi", [99] = "Yellow Yoshi", [100] = "Red Yoshi", [148] = "Black Yoshi", [149] = "Purple Yoshi", [150] = "Pink Yoshi", [169] = "Tanooki Suit", [170] = "Hammer Suit", [183] = "Fire Flower", [184] = "Mushroom", [185] = "Mushroom", [191] = "Podoboo Shoe", [194] = "Rainbow Shell", [228] = "Cyan Yoshi", [241] = "Pow-Block", [249] = "Mushroom", [250] = "Heart", [264] = "Ice Flower", [277] = "Ice Flower", [278] = "Propeller Block", [279] = "Flamethrower Propeller Block", [293] = "Starman", [325] = "Green Baby Yoshi", [326] = "Red Baby Yoshi", [327] = "Blue Yoshi", [328] = "Yellow Baby Yoshi", [329] = "Baby Black Yoshi", [330] = "Purple Baby Yoshi", [331] = "Pink Baby Yoshi", [332] = "Cyan Yoshi", [334] = "Snake Block", [419] = "Arrow Lift", [425] = "Mega Mushroom", [427] = "Red Spring", [428] = "Sideways Spring", [462] = "Heart", [666] = "Walking Rinka Block"}
local function getBoxName(id)
  if id == 0 then return "None" end
  local s = boxNameList[id]
  if s then return id.."("..s..")" end
  return id
end

local function textplusPBPrint(text, x, y)
  textplus.print{text = text, x = x, y = y, xscale = 2, yscale = 2, plaintext = true, font = textfont, priority = 9.99}
end

local function epitick(subdata)
  local input = menu.input
  local runs = worldstat.runs

  if input.left.time == 1 or (input.left.time > 20 and input.left.time % 15 == 0) then
		subdata.suboptionx = subdata.suboptionx - 1
    SFX.play(menu.aScroll)
	elseif input.right.time == 1 or (input.right.time > 20 and input.right.time % 15 == 0) then
		subdata.suboptionx = subdata.suboptionx + 1
    SFX.play(menu.aScroll)
	end
	if subdata.suboptionx <= 0 then
		subdata.suboptionx = math.max(1, #runs + 1)
	elseif subdata.suboptionx > #runs + 1 then
		subdata.suboptionx = 1
	end

	if input.up.time == 1 or (input.up.time > 20 and input.up.time % 15 == 0) then
		subdata.suboptiony = subdata.suboptiony - 1
    SFX.play(menu.aScroll)
	elseif input.down.time == 1 or (input.down.time > 20 and input.down.time % 15 == 0) then
		subdata.suboptiony = subdata.suboptiony + 1
    SFX.play(menu.aScroll)
	end
	local run
	if subdata.suboptionx == 1 then
		run = worldstat.best
	else
		run = worldstat.runs[subdata.suboptionx - 1]
	end
	if not run then return end
	if subdata.suboptiony <= 0 then
		subdata.suboptiony = math.max(1, #run.log)
	elseif subdata.suboptiony > #run.log then
		subdata.suboptiony = 1
	end
end

local function epidraw(subdata)
	local run
	if subdata.suboptionx == 1 then
		run = worldstat.best
		if not run then
      textplusPBPrint("No Records Found!", 8, 8)
			return
		end
	else
		run = worldstat.runs[subdata.suboptionx - 1]
	end

	local selection = run.log[subdata.suboptiony]
	local category = selection.category

	local heading = getSMBXVersionString(run.smbxversion)
	if subdata.suboptionx == 1 then heading = "(BEST) "..heading
	else heading = "("..(subdata.suboptionx - 1).."/"..#worldstat.runs..") "..heading  end
	textplusPBPrint("> "..heading,  8, 8 + 26*0)

	textplusPBPrint(formatTime(run.time).."  ["..run.time.."]",       8, 8 + 26*1)
	textplusPBPrint(run.date, 8, 8 + 26*2)


	local exitname = finTypes[category.type]
	if category.section ~= -1 then exitname = exitname.." @"..category.section end

	textplusPBPrint("("..(subdata.suboptiony).."/"..#run.log..") "..selection.name,   8, 8 + 26*5)
	textplusPBPrint(selection.date, 8, 8 + 26*6)
	textplusPBPrint(exitname,       8, 8 + 26*7)

	for k, v in ipairs({"powerup", "mult", "starcoin"}) do
		local sourceX, sourceY = 16*(k - 1), 0
		if category[v] then sourceY = 16 end
		Graphics.draw{type = RTYPE_IMAGE, x = 8 + 18*(k - 1), y = 8 + (26*8), priority = 9.99, image = iIcons, sourceX = sourceX, sourceY = sourceY, sourceWidth = 16, sourceHeight = 16}
	end

	textplusPBPrint(formatTime(selection.time).."  ["..selection.time.."]",       8, 8 + 26*9)
	textplusPBPrint("Attempts:"..selection.attempts,                              8, 8 + 26*10)

	for k, pstate in ipairs(selection.startstate) do
		textplusPBPrint(getCharName(pstate.character).."\n"..getCostumeName(pstate.costume).."\n"..getPowName(pstate.powerup).."\n"..getMountName(pstate.mount, pstate.mountcolor).."\n"..getBoxName(pstate.reserveBox).."\n"..pstate.health, 36 + (k - 1)*300, 8 + 26*11)
		for i = 1, 6 do
			Graphics.draw{type = RTYPE_IMAGE, x = 16 + (k - 1)*300, y = 8 + 26*11 + 18*(i - 1), priority = 9.99, image = iStat, sourceX = 16*(i - 1), sourceY = 0, sourceWidth = 16, sourceHeight = 16}
		end
	end
end


-- Register the menu
menu.register{name = "Check Episode PB", type = "submenu", subdata = {suboptionx = 1, suboptiony = 1}, input = epitick, render = epidraw}
menu.register{name = "Show Clock", type = "toggle", var = "showTimerClock"}
menu.register{name = "Show Frames", type = "toggle", var = "showTimerFrames"}
menu.register{name = "Timer Position", type = "list", var = "timerPosition", list = {"LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Timer Size", type = "list", var = "timerSize", list = {"SMALL", "MEDIUM", "LARGE"}}
menu.register{name = "Show Inputs", type = "toggle", var = "showInputs"}
menu.register{name = "Inputs Position", type = "list", var = "inputPosition", list = {"LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Show Attempts", type = "toggle", var = "showAttempts"}
menu.register{name = "Attempts Position", type = "list", var = "attemptsPosition", list = {"LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Show Section Split", type = "list", var = "sectionsplit", list = sectionsplittable(#levelstat)}
menu.register{name = "Transparent", type = "toggle", var = "transperent"}
menu.register{name = "Print Log", type = "toggle", var = "printlog"}




local function renderInputs(p, x, y)
	local opacity = 1
	if settings.transperent then opacity = 0.5 end
	for k, v in ipairs(keyname) do
		if p.rawKeys[v] then
			Graphics.draw{image = iInputs, type = RTYPE_IMAGE, x = x + 18*(k - 1), y = y, priority = 9.9, sourceX = 16*(k - 1), sourceWidth = 16, opacity = opacity, priority = 9.99}
		end
	end
end


function lib.onDraw()
  GameData._speedrunner_etimer = GameData._speedrunner_etimer + 1

  if settings.showTimerClock or settings.showTimerFrames then
    if #GameData._speedrunner_log > 0 then
      for i = 1, math.min(#GameData._speedrunner_log, 10) do
        local v = GameData._speedrunner_log[i]
        local s = formatTime(v.time)
        local d = formatTime(math.abs(v.diff or 0))
        if v.diff and v.diff > 0 then d = "+"..d
        elseif v.diff and v.diff < 0 then d = "-"..d
        else d = " "..d end
        textplus.print{text = s.." "..d, x = 792, y = 8 + 10*i, pivot = {1, 0}, priority = 9.99, font = textfont, xscale = 1, yscale = 1}
      end
    end

  end


	local timerx = timerX[settings.timerPosition]
	local timery = 592
  local timerh = timerSize[settings.timerSize]*12
	local timercolor = Color.white

	local inputx = inputX[settings.inputPosition]
	local inputy = 576

	local attemptx = timerX[settings.attemptsPosition]
	local attempty = 592
	local attemptcolor = Color.white

	if camera.width == 400 then
		timerx = timerXSplit[settings.timerPosition]
		inputx = inputXSplit[settings.inputPosition]
	end
	if camera.height == 300 then
		timery = 292
		inputy = 276
	end


	if settings.transperent then
		timercolor = Color.white..0.5
		attemptcolor = Color.white..0.5
	end

	if (settings.showTimerClock or settings.showTimerFrames) and settings.timerPosition == settings.attemptsPosition then
		attempty = timery - 32
	end

	if (settings.showTimerClock or settings.showTimerFrames) and settings.timerPosition == settings.inputPosition then
		inputy = timery - 36
	end

	if settings.showAttempts and settings.attemptsPosition == settings.inputPosition then
		inputy = inputy - 36
	end


	if settings.showInputs then
    if player2 then
      renderInputs(player, inputx, inputy - 18)
      renderInputs(player2, inputx, inputy)
    else
      renderInputs(player, inputx, inputy)
    end
	end

  if settings.showAttempts then
    textplus.print{text = "@0", x = attemptx, y = attempty, pivot = timerPivot[settings.attemptsPosition], priority = 9.99, font = textfont, xscale = timerSize[settings.timerSize], yscale = timerSize[settings.timerSize], color = timercolor}
	end

	if settings.showTimerClock or settings.showTimerFrames then
		textplus.print{text = formatTime(GameData._speedrunner_etimer, true), x = timerX[settings.timerPosition], y = 592, pivot = timerPivot[settings.timerPosition], priority = 9.99, font = textfont, xscale = timerSize[settings.timerSize], yscale = timerSize[settings.timerSize], color = timercolor}
  end
end

function lib.onInitAPI()
  registerEvent(lib, "onDraw", "onDraw")
end

return lib
