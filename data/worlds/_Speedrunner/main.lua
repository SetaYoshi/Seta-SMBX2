local speedrunner = {}

if isOverworld then
-- When playing in a world map
  GameData._speedrunner_inepisode = true
  require(getSMBXPath().."\\worlds\\_Speedrunner\\world_mode.lua")

-- When in the intro level
elseif mem(0x00B2C620, FIELD_WORD) == -1 then

-- When playing a level
else
  require(getSMBXPath().."\\worlds\\_Speedrunner\\level_mode.lua")
end

return speedrunner
