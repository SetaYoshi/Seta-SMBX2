local c1 = Color(0, 0, 0)
local c2 = Color(1, 1, 1)

local y1 = math.lerp(c1, c2, 0.0)
local y2 = math.lerp(c1, c2, 0.2)
local y3 = math.lerp(c1, c2, 0.4)
local y4 = math.lerp(c1, c2, 0.6)
local y5 = math.lerp(c1, c2, 0.8)
local y6 = math.lerp(c1, c2, 1.0)

Misc.dialog(y1, y2, y3, y4, y5, y6)