local lib = {}

-- Important data needed for the rest of the library
local PATH = getSMBXPath().."\\worlds\\_Speedrunner\\"
local textplus = require("textplus")
local playerManager = require("playerManager")
local starcoin = require("npcs/AI/starcoin")
local savestate = require("savestate")
local inEpisode = Misc.saveSlot() > 0

local function formatTime(t)
	if t < 0 then t = -t end
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
  else
    return table.concat({minutes, seconds, miliseconds}, ":")
  end
end

local function signSym(n)
	if n < 0 then
		return "-"
  end
	return "+"
end

local function tplusColorCode(s, n)
	if n < 0 then
		return "<color rainbow>"..s.."</color>"
	elseif n > 0 then
		return "<color red>"..s.."</color>"
	else
		return "<color gray>"..s.."</color>"
  end
end


-- Different speedrun categories
local catPowerup = false
local catMult = false
local catStarcoins = false

-- Set up the menu settings
local settingsLib = require(PATH.."settings.lua")
local settings = settingsLib.data


GameData._speeddata = GameData._speeddata or {}
local speeddata = GameData._speeddata

-- Reset timer when an episode run begins
if inEpisode then
	if speeddata.prevsavefile ~= Misc.saveSlot() or speeddata.prevepisodepath ~= Misc.episodePath() then
		speeddata.etimer = nil
		speeddata.log = nil
	end
	speeddata.prevepisodepath = Misc.episodePath()
	speeddata.prevsavefile = Misc.saveSlot()
end

-- Only save the attempt counter from being reset
local s_attemptcount = speeddata.attempt
local s_prevlevel = speeddata.prevLevel

-- reset gamedata to simulate the level being loaded for the first time
if settings.disableChecks and not inEpisode then
  _G.GameData = {_speeddata = {}, _repl = {log = {}, history = {}}, __activatedCheats = {}, _basegame = {bigSwitch = {}}, __checkpoints = { [Level.filename()] = {} } }
end

speeddata = GameData._speeddata

speeddata.attempt = s_attemptcount
speeddata.prevLevel = s_prevlevel

speeddata.etimer = speeddata.etimer or 0
speeddata.log = speeddata.log or {}

speeddata.logger = speeddata.logger or {}
speeddata.startState = speeddata.startState or {}
speeddata.timer = speeddata.timer or 0
speeddata.attempt = speeddata.attempt or 0
speeddata.starcoin = speeddata.starcoin or {}

-- Easy workaround to detect if the player collected the starcoins in a run
local starcoin_collect = starcoin.collect
starcoin.collect = function(coin)
	local CoinData = starcoin.getTemporaryData()
	if CoinData[coin.ai2] then
		speeddata.starcoin[coin.ai2] = true
	end
  -- Check if all the starcoins have been collected
  catStarcoins = (#speeddata.starcoin == starcoin.max()) and (#speeddata.starcoin > 0)

  starcoin_collect(coin)
end

-- Need to detect when a new level is loaded through the editor!
local prevLevel = speeddata.prevLevel
local currLevel = Misc.episodePath()..string.match(Level.filename(), "(.+)%..+$")
if prevLevel ~= currLevel then
	speeddata.logger = {}
  speeddata.startState = {}
	speeddata.attempt = 0
	speeddata.timer = 0
	speeddata.starcoin = {}
end
speeddata.prevLevel = currLevel

-- Images and lookups
local iInputs = Graphics.loadImage(PATH.."inputs.png")
local iIcons = Graphics.loadImage(PATH.."icons.png")
local iStat = Graphics.loadImage(PATH.."stat.png")
local textfont = textplus.loadFont("textplus/font/6.ini")

local timerX = {0, 8, 400, 792}
local timerXSplit = {0, 8, 200, 396}
local timerPivot = {vector(0, 0), vector(0, 1), vector(0.5, 1), vector(1, 1)}
local timerSize = {1, 2, 2.5}

local pList = {player, player2}
local keyname = {"left", "up", "down", "right", "jump", "altJump", "run", "altRun", "dropItem", "pause"}
local inputX = {0, 8, 310, 612}
local inputXSplit = {0, 8, 110, 212}

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

-- Important things to keep track of
local forceExitWarp = 0
local isFollowingSectionSplit = false
local sectionSplit = 1
local customFinish

local hasLevelWon
local hasEpisodeWon
local levelWinTimeDiff
local episodeWinTimeDiff

local prevBestRun
local savest
local hasbegun
local notif = {txt = "", timer = -1}

-- Things to log while playing the level!
local logger = speeddata.logger
logger.inputs = logger.inputs or {}
logger.sectionsplit = logger.sectionsplit or {}
logger.forcedState = logger.forcedState or {}
logger.onground = logger.onground or 0
logger.spinjump = logger.spinjump or 0
logger.sliding = logger.sliding or 0
for k, v in ipairs(keyname) do
	logger.inputs[v] = logger.inputs[v] or 0
end


-- Load the library that stores the level's PBs
local levelstatLib = require(PATH.."levelstat.lua")
local levelstat = levelstatLib.data

-- Load the library that stores the episodes's PBs
local worldstatLib
local worldstat
if inEpisode then
  worldstatLib = require(PATH.."worldstat.lua")
  worldstat = worldstatLib.data
end


-- Input manager for menu
local commander = require(PATH.."mycommander.lua")
commander.register{{menu = 192, delete = 46, savestate = 116, loadstate = 117, back = {name = "run"}, select = {name = "jump"}, up = {name = "up"},  down = {name = "down"}, left = {name = "left"}, right = {name = "right"}}}
--        192 is the tilde key | 46 is the delete key | 116 is the f5 key | 117 is the f6 key

-- Load the menu library and pass important data
local menu = require(PATH.."mymenu.lua")
menu.data = settings
menu.input = commander[1]
menu.save = settingsLib.save

menu.aScroll = Audio.SfxOpen(PATH.."scroll.ogg")
menu.aOpen = Audio.SfxOpen(PATH.."open.ogg")
menu.aClose = Audio.SfxOpen(PATH.."close.ogg")
menu.aSelect = Audio.SfxOpen(PATH.."select.ogg")

-- Inputs for the PBs menu
local logtick = function(subdata)
	local input = menu.input
	if input.up.time == 1 or (input.up.time > 20 and input.up.time % 15 == 0) then
		subdata.suboption = subdata.suboption - 1
    SFX.play(menu.aScroll)
	elseif input.down.time == 1 or (input.down.time > 20 and input.down.time % 15 == 0) then
		subdata.suboption = subdata.suboption + 1
    SFX.play(menu.aScroll)
	end
	if subdata.suboption <= 0 then
		subdata.suboption = math.max(1, #levelstat)
	elseif subdata.suboption > #levelstat then
		subdata.suboption = 1
	end

  if menu.input.delete.time == 180 then
    table.remove(levelstat, subdata.suboption)
    levelstatLib.save()
    SFX.play(43)
    if subdata.suboption > #levelstat then
  		subdata.suboption = 1
  	end
    menu.submenu = 0
  end
end


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

-- Render for PBs menu
local logdraw = function(subdata)
  if #levelstat == 0 then
    textplusPBPrint("No Records Found!", 8, 8)
		return
	end

	local selection = levelstat[subdata.suboption]
	local category = selection.category

	local heading = getSMBXVersionString(selection.smbxversion)
	if #levelstat > 1 then heading = "("..subdata.suboption.."/"..#levelstat..") "..heading end

	local exitname = finTypes[category.type]
	if category.section ~= -1 then exitname = exitname.." @"..category.section end

	textplusPBPrint("> "..heading,  8, 8 + 26*0)
	textplusPBPrint(Level.name(),   8, 8 + 26*1)
	textplusPBPrint(selection.date, 8, 8 + 26*2)
	textplusPBPrint(exitname,       8, 8 + 26*3)

	for k, v in ipairs({"powerup", "mult", "starcoin"}) do
		local sourceX, sourceY = 16*(k - 1), 0
		if category[v] then sourceY = 16 end
		Graphics.draw{type = RTYPE_IMAGE, x = 8 + 18*(k - 1), y = 8 + (26*4), priority = 9.99, image = iIcons, sourceX = sourceX, sourceY = sourceY, sourceWidth = 16, sourceHeight = 16}
	end

	textplusPBPrint(formatTime(selection.time).."  ["..selection.time.."]",       8, 8 + 26*5)
	textplusPBPrint("Attempts:"..selection.attempts,                              8, 8 + 26*6)

	for k, pstate in ipairs(selection.startstate) do
		textplusPBPrint(getCharName(pstate.character).."\n"..getCostumeName(pstate.costume).."\n"..getPowName(pstate.powerup).."\n"..getMountName(pstate.mount, pstate.mountcolor).."\n"..getBoxName(pstate.reserveBox).."\n"..pstate.health, 36 + (k - 1)*300, 8 + 26*8)
		for i = 1, 6 do
			Graphics.draw{type = RTYPE_IMAGE, x = 16 + (k - 1)*300, y = 8 + 26*8 + 18*(i - 1), priority = 9.99, image = iStat, sourceX = 16*(i - 1), sourceY = 0, sourceWidth = 16, sourceHeight = 16}
		end
	end
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

function sectionsplittable(max)
	local t = {"HIDE"}
	for i = 1, max do table.insert(t, tostring(i)) end
	return t
end

-- Register the menu
menu.register{name = "Check Episode PB", type = "submenu", subdata = {suboptionx = 1, suboptiony = 1}, input = epitick, render = epidraw, levelBanned = true}
menu.register{name = "Check Level PB", type = "submenu", subdata = {suboption = 1}, input = logtick, render = logdraw}

menu.register{name = "Timer Mode", type = "list", var = "timerMode", list = {"Clock", "Frame", "Clock + Frame"}}
menu.register{name = "Timer Size", type = "list", var = "timerSize", list = {"SMALL", "MEDIUM", "LARGE"}}

menu.register{name = "Position Timer", type = "list", var = "timerPosition", list = {"HIDE", "LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Position Inputs", type = "list", var = "inputPosition", list = {"HIDE", "LEFT", "CENTER", "RIGHT"}}
menu.register{name = "Position Attempts", type = "list", var = "attemptsPosition", list = {"HIDE", "LEFT", "CENTER", "RIGHT"}}

menu.register{name = "Show Section Split", type = "list", var = "sectionsplit", list = sectionsplittable(#levelstat)}

menu.register{name = "Transparent", type = "toggle", var = "transperent"}
menu.register{name = "Enable Popout", type = "toggle", var = "popout", episodeBanned = true}
menu.register{name = "Print Log", type = "toggle", var = "printlog"}
menu.register{name = "Disable Checkpoints", type = "toggle", var = "disableChecks", episodeBanned = true}
menu.register{name = "Enable Savestate HotKeys", type = "toggle", var = "enablesavestate", episodeBanned = true}
menu.register{name = "Enable Extra Advantage Start Features", type = "toggle", var = "enableas", episodeBanned = true}
menu.register{name = "[AS] P1 Costume", type = "list", var = "asCostume1", list = costumelist, episodeBanned = true}
menu.register{name = "[AS] P2 Costume", type = "list", var = "asCostume2", list = costumelist, episodeBanned = true}
menu.register{name = "[AS] P1 Reserve Box", type = "numpad", var = "asBox1", min = 0, max = NPC_MAX_ID, episodeBanned = true}
menu.register{name = "[AS] P2 Reserve Box", type = "numpad", var = "asBox2", min = 0, max = NPC_MAX_ID, episodeBanned = true}
menu.register{name = "[AS] P1 Health", type = "list", var = "asHealth1", list = {"1", "2", "3"}, episodeBanned = true}
menu.register{name = "[AS] P2 Health", type = "list", var = "asHealth2", list = {"1", "2", "3"}, episodeBanned = true}

-- Check if the episode or level has a custom finish
local file = io.open(Misc.episodePath().."custom_finish.spddat", "r") -- r read mode
if file then
	customFinish = file:read("*all") -- *a or *all reads the whole file
	file:close()
end

-- Checks if a player has an "advantage" (not small default)
local hasHealth = {[CHARACTER_PEACH] = true, [CHARACTER_TOAD] = true, [CHARACTER_LINK] = true, [CHARACTER_KLONOA] = true, [CHARACTER_ROSALINA] = true}
local function checkadvantage(p)
  return playerManager.getCostume(p.character) or p.powerup ~= 1 or p.mount ~= 0 or (hasHealth[p.character] and p:mem(0x16,	FIELD_WORD) ~= 1) or (not hasHealth[p.character] and p.reservePowerup ~= 0)
end

-- Checks if the table share the same values
local function sameTable(t1, t2)
  for k, v in pairs(t1) do
    if v ~= t2[k] then
      return false
    end
  end
  return true
end

local function displayPopout(finType, exitSection)
	local title = "SPEEDRUNNER POPOUT - LEVEL COMPLETE"
	if levelWinTimeDiff then
		if levelWinTimeDiff < 0 then
			title = "SPEEDRUNNER POPOUT - NEW BEST"
		elseif levelWinTimeDiff > 0 then
			title = "SPEEDRUNNER POPOUT - BETTER LUCK NEXT TIME"
		else
			title = "SPEEDRUNNER POPOUT - TIED UP THE LEVEL"
		end
	end


	local txt = "=== "..Level.name().." ===\n"
	txt = txt.."SMBX VERSION: "..getSMBXVersionString(SMBX_VERSION).."\n"
	txt = txt.."TIMESTAMP: "..os.date().."\n"
	txt = txt.."TYPE: "..finTypes[finType].."   @"..exitSection.."\n"
	txt = txt.."\n"
	txt = txt.."TIME CLOCK: "..formatTime(speeddata.timer).."\n"
	txt = txt.."TIME FRAME: "..speeddata.timer.."\n"
	if levelWinTimeDiff then
		txt = txt.."CURRENT BEST CLOCK: "..formatTime(speeddata.timer - levelWinTimeDiff).."\n"
		txt = txt.."CURRENT BEST FRAME: "..speeddata.timer - levelWinTimeDiff.."\n"
		local sign = signSym(levelWinTimeDiff)
		txt = txt.."TIME DIFFERENCE OF: "..sign..formatTime(levelWinTimeDiff).." ["..levelWinTimeDiff.."]\n"
	end
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt.."CATEGORIES:\n"
	txt = txt.."  * Advatage Start: "..tostring(catPowerup).."\n"
	txt = txt.."  * Multiplayer: "..tostring(catMult).."\n"
	txt = txt.."  * Starcoins: "..tostring(catStarcoins).."\n"
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt.."PLAYER:\n"
	local pstate = speeddata.startState[1]
	txt = txt.."  * CHARACTER: "..getCharName(pstate.character).."\n"
	txt = txt.."  * COSTUME: "..getCostumeName(pstate.costume).."\n"
	txt = txt.."  * POWERUP: "..getPowName(pstate.powerup).."\n"
	txt = txt.."  * MOUNT: "..getMountName(pstate.mount, pstate.mountcolor).."\n"
	txt = txt.."  * HEALTH: "..pstate.health.."\n"
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt.."SECTION:\n"
	for k, v in pairs(logger.sectionsplit) do
		txt = txt.."  * "..v.id..": "..formatTime(v.time).." ["..v.time.."]".."  %"..(math.floor(v.time/speeddata.timer*10000)/100).."\n"
	end
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt.."INPUTS:\n"
	for k, v in pairs(logger.inputs) do
		txt = txt.."  * "..k..": "..formatTime(v).." ["..v.."]".."  %"..(math.floor(v/speeddata.timer*10000)/100).."\n"
	end
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt.."FORCED STATES:\n"
	for k, v in pairs(logger.forcedState) do
		txt = txt.."  * "..k..": "..formatTime(v).." ["..v.."]".."  %"..(math.floor(v/speeddata.timer*10000)/100).."\n"
	end
	txt = txt.."\n"
	txt = txt.."\n"
	txt = txt.."MISC:\n"
	txt = txt.."  * ON GROUND: "..formatTime(logger.onground).." ["..logger.onground.."]".."  %"..(math.floor(logger.onground/speeddata.timer*10000)/100).."\n"
	txt = txt.."  * SLIDING: "..formatTime(logger.sliding).." ["..logger.sliding.."]".."  %"..(math.floor(logger.sliding/speeddata.timer*10000)/100).."\n"
	txt = txt.."  * SPIN JUMPING: "..formatTime(logger.spinjump).." ["..logger.spinjump.."]".."  %"..(math.floor(logger.spinjump/speeddata.timer*10000)/100).."\n"

  if settings.printlog then
		time = os.date("*t")
		local writefile = io.open(Misc.episodePath().."LOG "..time.year..","..timer.month..","..time.day.." - "..time.hour ..",".. time.min ..",".. time.sec.." "..string.match(Level.filename(), "(.+)%..+$")..".txt", "w")
		if not writefile then return end

		writefile:write(txt)
		writefile:close()
	end
	if settings.popout and not inEpisode then
		Misc.showRichDialog(title, txt, true)
	end
end


local function timeFinish(finType, finSec)
  finSec = finSec or -1

  hasLevelWon = true
  if finType == 10 or finType == LEVEL_END_STATE_GAMEEND then
    hasEpisodeWon = true
  end

  -- Create run object
  local category = {type = finType, section = finSec, powerup = catPowerup, mult = catMult, starcoin = catStarcoins}
  local newLevelRun = {diff = levelWinTimeDiff, category = category, time = speeddata.timer, sectionsplit = logger.sectionsplit, date = os.date(), attempts = speeddata.attempt, smbxversion = SMBX_VERSION, startstate = speeddata.startState, name = Level.name()}

  -- Check if there is a run stored of the same category
	local oldLevelRun, oldLevelRunKey
  for k, v in ipairs(levelstat) do
    if sameTable(category, v.category) then
      oldLevelRunKey, oldLevelRun = k, v
      break
    end
  end

  -- If a run of the same category exists, then get the diff. time
	if oldLevelRun then levelWinTimeDiff = newLevelRun.time - oldLevelRun.time end

  -- Show log
  displayPopout(finType, finSec)

  -- Save the run if its a new best time!
  if not oldLevelRun then
    table.insert(levelstat, newLevelRun)
  elseif newLevelRun.time < oldLevelRun.time then
		prevBestRun = oldLevelRun
		levelstat[oldLevelRunKey] = newLevelRun
	end
  levelstatLib.save()

  if inEpisode then
    -- When playing in an episode, log the level to the episode data
    table.insert(speeddata.log, 1, newLevelRun)

    -- When the episode is beaten
    if hasEpisodeWon then
      local newEpisodeRun = {time = speeddata.etimer, date = os.date(), smbxversion = SMBX_VERSION, log = speeddata.log}
      local oldEpisodeRun = worldstat.best

      -- Get the time diff for an episode run
      if oldEpisodeRun then
        episodeWinTimeDiff = newEpisodeRun.time - oldEpisodeRun.time
      end

      -- Save the run if its a new best time!
      if not oldEpisodeRun or newEpisodeRun.time < oldEpisodeRun.time then
        worldstat.best = newEpisodeRun
      end

      -- Save the run into the run history
      table.insert(worldstat.runs, 1, newEpisodeRun)
      worldstat.runs[51] = nil -- Only save the latest 50 runs
      worldstatLib.save()
    end
  end
end



function lib.onStart()
	-- Keep track amount of attempts in the run
	speeddata.attempt = speeddata.attempt + 1

  -- Advantage start features the editor is missing
	if settings.enableas then
		-- Costume
		playerManager.setCostume(player.character, costumelist[settings.asCostume1])
		if player2 then playerManager.setCostume(player2.character, costumelist[settings.asCostume2]) end
    -- Reserve Box
		player.reservePowerup = settings.asBox1
		if player2 then player2.reservePowerup = settings.asBox2 end

    -- Health
		player:mem(0x16, FIELD_WORD, settings.asHealth1)
		if player2 then player2:mem(0x16,	FIELD_WORD, settings.asHealth2) end
	end

	-- Detect if the player begins with any powerups, monuts, etc
	catPowerup = checkadvantage(player)

  -- Detect if the level is being played in multiplayer
	if player2 then
		catMult = true
		if not catPowerup then catPowerup = checkadvantage(player2) end
	end

	-- Store initial player data
	-- character, costume, powerup, mount, reserveBox, health
	if not speeddata.startState[1] then
		local startState = speeddata.startState
    for k, p in ipairs(pList) do
			startState[k] = {
				character = p.character,
				costume = playerManager.getCostume(p.character),
				powerup = p.powerup,
				mount = p.mount,
				mountcolor = p.mountColor,
				reserveBox = p.reservePowerup,
				health = p:mem(0x16, FIELD_WORD)
			}
    end
	end
end

function lib.onTick()
	-- Check for inputs
	if settings.enablesavestate and not inEpisode then
		if menu.input.savestate.state == KEYS_PRESSED then
			SFX.play(menu.aSelect)
			savest = savestate.save()
			notif = {text = "Savestate Saved", timer = 0}
		elseif menu.input.loadstate.state == KEYS_PRESSED and savest then
			SFX.play(menu.aClose)
			savestate.load(savest)
			notif = {text = "Savestate Loaded", timer = 0}
		end
	end

	-- Log data for the logger
  for k, v in pairs(player.keys) do
    if v then
			logger.inputs[k] = logger.inputs[k] + 1
		end
	end

	if player.forcedState ~= 0 then
		logger.forcedState[player.forcedState] = (logger.forcedState[player.forcedState] or 0) + 1
	end

	if player.isOnGround then
	  logger.onground = logger.onground + 1
	end

	if player:mem(0x3C, FIELD_BOOL) then -- is Sliding
		logger.sliding = logger.sliding + 1
	end

	if player:mem(0x50, FIELD_BOOL) then -- is Spinjumping
		logger.spinjump = logger.spinjump + 1
	end
end

function lib.onDraw()
	-- Detection when the level has been finished
	if Level.winState() ~= 0 and not hasLevelWon then
    timeFinish(Level.winState(), player.section)
	end

	-- Count the level timer
  if not hasLevelWon then
		speeddata.timer = speeddata.timer + 1

    -- Section logger!
		if logger.prevSection ~= player.section then
			table.insert(logger.sectionsplit, {id = player.section, time = 0})
		end
		logger.sectionsplit[#logger.sectionsplit] = logger.sectionsplit[#logger.sectionsplit] or {id = player.section, time = 0}
		logger.sectionsplit[#logger.sectionsplit].time = logger.sectionsplit[#logger.sectionsplit].time + 1
		logger.prevSection = player.section
  end

  -- Count the episode timer
  if inEpisode and not hasEpisodeWon then
    speeddata.etimer = speeddata.etimer + 1
  end

  -- Fix to force exit by warp be detected
	for k, p in ipairs(Player.get()) do
		if p.prevWarp and p.prevWarp > 0 and p:mem(0x122, FIELD_WORD) > 0 then
			local warp = Warp.get()[p.prevWarp]
			if warp and (warp.toOtherLevel or warp.levelFilename ~= "") then
				forceExitWarp = k
			end
		end
		p.prevWarp = p:mem(0x5A, FIELD_WORD)
	end

end

local function formatOut(n)
	if settings.timerMode == 1 then
		return formatTime(n)
	elseif settings.timerMode == 2 then
		return tostring(n)
	elseif settings.timerMode == 3 then
		return formatTime(n).." ["..n.."]"
	end
end

local function formatFin(obj, diff)
	local sym = signSym(diff)

	if diff < 0 then
		obj.text = "<color rainbow>"..obj.text.."</color>"
	elseif diff > 0 then
		obj.color = Color.red
	else
		obj.color = Color.gray
	end

	obj.text = obj.text.." <color white>"..sym..formatOut(diff).."</color>"
end

local function renderInputs(p, x, y)
	for k, v in ipairs(keyname) do
		local opacity = 1
		local sourceX = k - 1
		local sourceY = 16
		if settings.transperent then opacity = 0.5 end
		if p.character == CHARACTER_PEACH and v == "altJump" then
			sourceX = 10
		end
		if not p.rawKeys[v] then
			opacity = opacity*0.25
			sourceY = 0
		end
		Graphics.draw{image = iInputs, type = RTYPE_IMAGE, x = x + 18*(k - 1), y = y, priority = 9.9, sourceX = 16*sourceX, sourceY = sourceY, sourceHeight = 16, sourceWidth = 16, opacity = opacity, priority = 9.99}
	end
end


-- Draw the timer and inputs
function lib.onCameraDraw(idx)
	-- These are the objects that will be printed onscreen
	local opacity = 1
	local timerObj = {x = timerX[settings.timerPosition], pivot = timerPivot[settings.timerPosition], priority = 9.99, font = textfont, xscale = timerSize[settings.timerSize], yscale = timerSize[settings.timerSize], color = Color.white, height = timerSize[settings.timerSize]*12}
  local attemptObj = {text = "#"..speeddata.attempt, x = timerX[settings.attemptsPosition], pivot = timerPivot[settings.attemptsPosition], priority = 9.99, font = textfont, xscale = 2, yscale = 2, color = Color.white, height = 16}
  local inputObj = {x = inputX[settings.inputPosition], height = 16}

  -- Change position if there is splitscreen
	if camera.width == 400 then
		timerObj.x = timerXSplit[settings.timerPosition]
		attemptObj.x = timerXSplit[settings.attemptsPosition]
		inputObj.x = inputXSplit[settings.inputPosition]
	end

	-- Print the text depending on the format needed
	timerObj.text = formatOut(speeddata.timer)

  -- Make text transperent
	if settings.transperent then
		opacity = 0.5
	end

	if inEpisode then
		timerObj.height = timerObj.height*2
	end

	if camera.width == 800 and camera.height == 600 and player2 then
		inputObj.height = inputObj.height*2
	end

	-- Change the y position if multiple objects overlap
	--[[
	    * attempt
			* input
			* time (level)
			* time (episode)
	--]]

	timerObj.y = 592

	if settings.timerPosition > 1 and settings.timerPosition == settings.inputPosition then
		inputObj.y = timerObj.y - timerObj.height
	else
		inputObj.y = 592
	end

	if settings.inputPosition > 1 and settings.inputPosition == settings.attemptsPosition then
		attemptObj.y = inputObj.y - inputObj.height - 4
	elseif settings.timerPosition > 1 and settings.timerPosition == settings.attemptsPosition then
		attemptObj.y = timerObj.y - timerObj.height
	else
		attemptObj.y = 592
	end

	if camera.height == 300 then
		attemptObj.y = attemptObj.y - 300
		inputObj.y = inputObj.y - 300
		timerObj.y = timerObj.y - 300
	end

	-- Print inputs
	if settings.inputPosition > 1 then
		if camera.width == 800 and camera.height == 600 and player2 then
			renderInputs(player, inputObj.x, inputObj.y - inputObj.height - 4)
			renderInputs(player2, inputObj.x, inputObj.y - inputObj.height*0.5)
		else
			renderInputs(pList[idx], inputObj.x, inputObj.y - inputObj.height)
		end
	end

	-- Print attempts
	if settings.attemptsPosition > 1 then
		attemptObj.color = attemptObj.color*opacity
		textplus.print(attemptObj)
	end

	-- Print timer (level and episode)
	if settings.timerPosition > 1 and timerObj.text then
		if hasLevelWon and levelWinTimeDiff then
			formatFin(timerObj, levelWinTimeDiff)
		end

		local etimerObj
	  if inEpisode then
		  etimerObj = table.clone(timerObj)
	  end

		timerObj.color = timerObj.color*opacity
		textplus.print(timerObj)

		if inEpisode then
			etimerObj.y = timerObj.y - etimerObj.height*0.5
			etimerObj.text = formatOut(speeddata.etimer)

			if hasEpisodeWon and episodeWinTimeDiff then
				formatFin(etimerObj, episodeWinTimeDiff)
			end

			etimerObj.color = etimerObj.color*opacity
			textplus.print(etimerObj)
		end
	end

	-- Print the category when the level is finished
	if hasLevelWon then
		for k, v in ipairs({catPowerup, catMult, catStarcoins}) do
			local xs, ys = 16*(k - 1), 0
			if v then ys = 16 end
			Graphics.draw{type = RTYPE_IMAGE, x = 16 + 18*(k - 1) - 4, y = 8 + 4, priority = 9.99, image = iIcons, sourceX = xs, sourceY = ys, sourceWidth = 16, sourceHeight = 16}
		end
	end

	-- Print the notification
	if notif.timer >= 0 then
		notif.timer = notif.timer + 1
		local off = 0
		if notif.timer < 10 then
			off = 32*math.sin(notif.timer*0.3)
		elseif notif.timer > 120 then
			notif.timer = -1
		end
		textplus.print{text = notif.text, x = 760  + off, y = 8, pivot = {1, 0}, priority = 9.99, font = textfont, xscale = 2, yscale = 2, plaintext = true, color = Color.red*opacity}
	end

	-- Print the section splitter
	if settings.sectionsplit > 0 then
		local selectedRun = levelstat[settings.sectionsplit - 1]
		if not selectedRun then
			settings.sectionsplit = 1
			return
		end

		local selectedCat = selectedRun.category
		local secList = selectedRun.sectionsplit
		if prevBestRun then
			secList = prevBestRun.sectionsplit
		end

		-- Print exit name type and section
		local exitname = finTypes[selectedCat.type]
		if selectedCat.section ~= -1 then exitname = exitname.." @"..selectedCat.section end
		textplus.print{text = exitname, x = 800 - 8, y = 8, pivot = {1, 0}, priority = 9.99, font = textfont, color = Color.white*opacity}

		-- Print category icons
		for k, v in ipairs({"powerup", "mult", "starcoin"}) do
			local sourceX, sourceY = 16*(k - 1), 0
			if selectedCat[v] then sourceY = 16 end
			Graphics.draw{type = RTYPE_IMAGE, x = 800 - 6  - (3 - k + 1)*18, y = 8 + 10, priority = 9.99, image = iIcons, sourceX = sourceX, sourceY = sourceY, sourceWidth = 16, sourceHeight = 16, opacity = opacity}
		end

		-- Print timers
		for k, v in ipairs(secList) do
			local t = formatTime(v.time)
			local splitColor = Color.white
			if logger.sectionsplit[k] and logger.sectionsplit[k].id == v.id then
				local d = logger.sectionsplit[k].time - v.time
				t = signSym(d)..formatTime(d)
				if d < 0 then t = "<color rainbow>"..t.."</color>"
			  elseif d > 0 then splitColor = Color.red
				else splitColor = Color.gray end
				splitColor = splitColor*opacity
			end

      textplus.print{text = t, x = 800 - 8, y = 8 + 18+10 + 8 + (k - 1)*10, pivot = {1, 0}, priority = 9.99, font = textfont, color = splitColor}
		end
	end
end

function lib.onExitLevel(type)
  -- Fix for exit by warp
  if forceExitWarp ~= 0 then type = LEVEL_WIN_TYPE_WARP end

	if type ~= 0 then
    if not hasLevelWon then
      -- Detection when the level has been finished (for win types not accounted by Level.winState())
      hasLevelWon = true
      if type == LEVEL_WIN_TYPE_OFFSCREEN then
        timeFinish(8, player.section)
      elseif type == LEVEL_WIN_TYPE_WARP then
        timeFinish(9, player.section)
      end
    end
  end

  -- This means the level was "beat"
  if hasLevelWon then
		speeddata.logger = nil
    speeddata.timer = nil
    speeddata.starcoin = nil
    speeddata.attempt = nil
    speeddata.startState = nil
  end

  -- This means the episide was "beat"
  if hasEpisodeWon then
    speeddata.etimer = nil
    speeddata.log = nil
  end

	-- If checkpoints are disabled, force the level to reload as if it was loaded for the first time
	if settings.disableChecks and not inEpisode then
    Checkpoint.reset()
    mem(0x00B250B0, FIELD_STRING, "") -- Clear vanilla checkpoint
		mem(0x00B2C5A8,	FIELD_WORD, 0)	-- Clear coins
		mem(0x00B2C8E4,	FIELD_DWORD, 0) -- Clear score
		SaveData.clear()
		Misc.saveGame()
  end
  -- Misc.dialog(GameData._speeddata)
	-- local s = require("ext/serializer")
	-- Misc.dialog(s.serialize(speeddata))
	-- Misc.dialog(s.serialize(GameData))
  --GameData._speeddata = nil
end

-- For when the episode has a custom end game
function lib.onEvent(eventname)
  if eventname == customFinish then
    timeFinish(10, player.section)
	end
end

Misc.cheatBuffer("SMBXSPEEDRUNNER")
function lib.onInputUpdate()
  if Misc.cheatBuffer() == "" then
		SFX.play(menu.aScroll)
    Misc.cheatBuffer("SPEEDRUNNER")
    notif = {text = "CHEAT DETECTED", timer = 0}
  end
end


function lib.onInitAPI()
	registerEvent(lib, "onStart", "onStart")
	registerEvent(lib, "onEvent", "onEvent")
	registerEvent(lib, "onInputUpdate", "onInputUpdate")
	registerEvent(lib, "onTick", "onTick")
  registerEvent(lib, "onDraw", "onDraw")
	registerEvent(lib, "onCameraDraw", "onCameraDraw")
	registerEvent(lib, "onExitLevel", "onExitLevel")
end

return lib
