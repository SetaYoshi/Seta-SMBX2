local lib = {}

-- TODO
--[[
  Need to update the transforms to use 3D transforms to store priority. Use Z axis so children always appear in front of parents
  Need a show and hide method for each style
  Need to standarize the method in which children widgets are attached to a parent
  Need to finish the lib itself :)
]]


--[[


   .----------------.  .----------------.
  | .--------------. || .--------------. |
  | | _____  _____ | || |     _____    | |
  | ||_   _||_   _|| || |    |_   _|   | |
  | |  | |    | |  | || |      | |     | |
  | |  | '    ' |  | || |      | |     | |
  | |   \ `--' /   | || |     _| |_    | |
  | |    `.__.'    | || |    |_____|   | |
  | |              | || |              | |
  | '--------------' || '--------------' |
   '----------------'  '----------------'

  By SetaYoshi

--]]

local widgetList = {}


-- ============================
-- ||                        ||
-- ||      DEFINITIONS       ||
-- ||                        ||
-- ============================

--[[
  -- || FUNCTIONS || --
--]]

local cursor = require("ui/cursor")
local textplus = require("textplus")

local clamp = math.clamp
local char, sub = string.char, string.sub

local string_insert = function(str1, str2, pos)
    return str1:sub(1, pos)..str2..str1:sub(pos + 1)
end

local string_remove = function(str, pos)
  return sub(str, 1, pos - 1)..sub(str, pos + 1, #str)
end

local function getCursorPos(scenecoords)
  return (scenecoords and cursor.scenepos) or cursor.screenpos
end


--[[
  -- || BUFFER || --
  Custom text buffer to be used throughout the library
  This is to simplify the capturing of text inputs
--]]

local buffer = {}
lib.buffer = buffer

buffer.active = false
buffer.value = ""
buffer.position = 1
buffer.debug = false

local function bufferFilter_none(id)
  return true
end

local function bufferFilter_integer(id)
  return (id >= 48 and id <= 57) or (id >= 96 and id <= 105)
end

local function bufferFilter_double(id)
  return (id >= 48 and id <= 57) or (id >= 96 and id <= 105) or id == 110 or id == 190
end

buffer.filter = bufferFilter_none

--[[
  -- || METATABLES || --
  Let's simplify the work!
--]]

local function getPos(t)
  return (t.parent and t.wposition) or t.position
end

local mt = {}

mt.__type = "widget"

mt.__index = function(t, k)
  if k == "position" then  -- Shorcut to get coordinates in vector form
    return vector(t.transform.wposition.x, t.transform.wposition.y)
  elseif k == "x" then      -- Shorcut to get x position
    return t.transform.wposition.x
  elseif k == "y" then      -- Shorcut to get y position
    return t.transform.wposition.y
  elseif k == "priority" then      -- Shorcut to get priority
    return t.transform.wposition.z
  elseif k == "child" then  -- Alias between child and children
    return (t.children or {})[1]
  elseif k == "childPivot" then
    return (t.childrenPivot or {})[1]
  else
    return rawget(t, k)
  end
end

mt.__newindex = function(t, k, v)
  if k == "position" then
    t.transform.wposition = vector(v.x, v.y, t.transform.wposition.z)
    t:updatePosition()
  elseif k == "x" then
    t.transform.wposition = vector(v, t.transform.wposition.y, t.transform.wposition.z)
    t:updatePosition()
  elseif k == "y" then
    t.transform.wposition = vector(t.transform.wposition.x, v, t.transform.wposition.z)
    t:updatePosition()
  elseif k == "priority" then
    t.transform.wposition = vector(t.transform.wposition.x, t.transform.wposition.y, v)
    t:updatePosition()
  elseif k == "child" then
    t.children = {v}
  elseif k == "childPivot" then
    t.children = {v}
  else
    rawset(t, k, v)
  end
end


-- ============================
-- ||                        ||
-- ||         STYLES         ||
-- ||                        ||
-- ============================

local function style_create(args, f)
  args = args or {}
  return function(ui)
    f(ui, args)
  end
end

--[[
  -- || NONE || --
  A 'none' style that does nothing. Used as a template
--]]

local style_none_create = function(ui, args)
  local data = ui.data
  -- Here you can alter properties of the ui and create variables for style support
end

-- This function runs every tick. Can be used to create custom animation or specialized styling
local style_none_tick = function(ui)
end

-- This function draws the widget. This is the core part of a style
local style_none_draw = function(ui)
end

local style_none_show = function(ui)
  ui.active = true
end

local style_none_hide = function(ui)
  ui.active = false
end



--[[
  -- || Raised Button || --
  An interactive button that reacts when the cursor is over the button and when pressed
--]]

local style_raisedbutton_create = function(ui, args)
  local data = ui.data

  data.color = args.color or Color.blue
  data.pressedOffset = args.pressedOffset or vector(0, 2)
  data.debug = args.debug
  data.offset = vector(0, 0)
end


local function style_raisedbutton_tick(ui)
  if ui.state == 'held' and ui.prevstate ~= 'held' then
    ui.data.offset = ui.data.pressedOffset

    if ui.child then
      ui.child.position = ui.child.position + ui.data.pressedOffset
    end
  elseif ui.state ~= 'held' and ui.prevstate == 'held' then
    ui.data.offset = vector(0, 0)

    if ui.child then
      ui.child.position = ui.child.position - ui.data.pressedOffset
    end
  end
end

-- This function draw the widget. This is the core part of a style
local style_raisedbutton_draw = function(ui)
  local color = ui.data.color

  if ui.state == 'selected' then
    color = math.lerp(color, Color.black, 0.2)
  elseif ui.state == 'held' then
    color = math.lerp(color, Color.black, 0.4)
  elseif ui.state == 'locked' then
    color = math.lerp(color, Color.black, 0.8)
  end

  Graphics.drawBox{x = ui.x + ui.data.offset.x, y = ui.y + ui.data.offset.y, width = ui.width, height = ui.height, color = color, sceneCoords = ui.sceneCoords, priority = ui.priority}

  if ui.data.debug then
    textplus.print{text = "Priority: "..ui.priority.."\nState: ".. ui.state.."\nSelected: "..ui.selectedTimer.."\nHeld: "..ui.heldTimer.."\nReleased: "..ui.releasedTimer, x = ui.x, y = ui.y + ui.height}
  end
end



--[[
  -- || Dot Drag Box || --
  An interactive button that reacts when the cursor is over the button and when pressed
--]]

local style_dotdragbox_create = function(ui, args)
  local data = ui.data

  for k, v in pairs(args) do
    data[k] = v
  end

  data.color = data.color or Color.orange
  data.dotHeight = data.dotHeight or 16
  ui.dragCollider.height = data.dotHeight
end


-- This function draw the widget. This is the core part of a style
local style_dotdragbox_draw = function(ui)
  local color = ui.data.color

  if ui.state == 'none' then
    color = math.lerp(color, Color.black, 0.2)
  elseif ui.state == 'selected' then
    color = math.lerp(color, Color.black, 0.4)
  elseif ui.state == 'held' then
    color = math.lerp(color, Color.black, 0.6)
  end

  Graphics.drawBox{x = ui.x, y = ui.y, width = ui.width, height = ui.height, color = ui.data.color, sceneCoords = ui.sceneCoords, priority = ui.priority}
  Graphics.drawBox{x = ui.x, y = ui.y, width = ui.width, height = ui.data.dotHeight, color = color, sceneCoords = ui.sceneCoords, priority = ui.priority}

  if ui.data.debug then
    textplus.print{text = "Priority: "..ui.priority.."\nState: ".. ui.state.."\nSelected: "..ui.selectedTimer.."\nHeld: "..ui.heldTimer.."\nReleased: "..ui.releasedTimer, x = ui.x, y = ui.y + ui.height}
  end
end


--[[
  -- || Textplus || --
  An interactive button that reacts when the cursor is over the button and when pressed
--]]

local style_textplus_create = function(ui, args)
  local data = ui.data

  for k, v in pairs(args) do
    data[k] = v
  end

  data.color = data.color or Color.white

  if data.scale then
    data.xscale = data.scale
    data.yscale = data.scale
  else
    data.xscale = data.xscale or 2
    data.yscale = data.yscale or 2
  end

  data.parse = textplus.parse(ui.text, data)
  data.layout = textplus.layout(data.parse)

  if not data.disableAutoSize then
    ui.width = data.layout.width
    ui.height = data.layout.height
  end
end

local style_textplus_draw = function(ui)
  local data = ui.data

  local textOut = table.clone(ui.data)
  textOut.layout = data.layout
  textOut.x = ui.x
  textOut.y = ui.y
  textOut.priority = ui.priority

  textplus.render(textOut)
end


--[[
  -- || Invisible Row || --
  Invisible row style
--]]

local style_invirow_create = function(ui, args)
  local data = ui.data

  for k, v in pairs(args) do
    data[k] = v
  end
end


-- This function draw the widget. This is the core part of a style
local style_invirow_draw = function(ui)



  if ui.data.debug then
    Graphics.drawBox{x = ui.x, y = ui.y, width = ui.width, height = ui.height, color = Color.red..0.2, sceneCoords = ui.sceneCoords, priority = ui.priority}

    if ui.children then
      local boxHeight = ui.height/#ui.children
      Graphics.drawBox{x = ui.x, y = ui.y, width = ui.width, height = 4, color = Color.red..0.9, sceneCoords = ui.sceneCoords, priority = ui.priority}
      for k in ipairs(ui.children) do
        Graphics.drawBox{x = ui.x, y = ui.y + boxHeight*k - 4, width = ui.width, height = 4, color = Color.red..0.9, sceneCoords = ui.sceneCoords, priority = ui.priority}
      end
    end
  end
end

--[[
  -- || Invisible Column || --
  Invisible column style
--]]

local style_invicolumn_create = function(ui, args)
  local data = ui.data

  for k, v in pairs(args) do
    data[k] = v
  end
end


-- This function draw the widget. This is the core part of a style
local style_invicolumn_draw = function(ui)
  if ui.data.debug then
    Graphics.drawBox{x = ui.x, y = ui.y, width = ui.width, height = ui.height, color = Color.blue..0.2, sceneCoords = ui.sceneCoords, priority = ui.priority}

    if ui.children then
      local boxWidth = ui.width/#ui.children
      Graphics.drawBox{x = ui.x, y = ui.y, width = 4, height = ui.height, color = Color.blue..0.9, sceneCoords = ui.sceneCoords, priority = ui.priority}
      for k in ipairs(ui.children) do
        Graphics.drawBox{x = ui.x + boxWidth*k - 4, y = ui.y, width = 4, height = ui.height, color = Color.blue..0.9, sceneCoords = ui.sceneCoords, priority = ui.priority}
      end
    end
  end
end

-- [[======================]]
-- ||     CONSTRUCTORS     ||
-- [[======================]]

function lib.registerStyle(name, create, tick, draw, show, hide)
  realName = "Style_"..name

  if lib[realName] then
    Misc.warn('Ovelap in style name: '..name..". Please use a different name")
  end

  if not create then create = lib.style_none_initialize end
  if not show then show = lib.style_none_show end
  if not hide then hide = lib.style_none_show end

  lib[realName] = function(args) return {create = style_create(args, create), tick = tick, draw = draw, show = show, hide = hide} end
end



-- [NONE] A style that does nothing
lib.registerStyle("None", style_none_create, style_none_tick, style_none_draw, style_none_show, style_none_hide)


-- [BUTTON] A button that moves down when pressed, giving it the effect that the button is 'raised'
-- @ color         [Color]   [blue]
-- @ pressedOffset [vector2] [0, 2]
-- @ debug         [bool]    [false]
lib.registerStyle('RaisedButton', style_raisedbutton_create, style_raisedbutton_tick, style_raisedbutton_draw)

-- [DRAGBOX] A dragbox with three dots in the top indicating it can be dragged
-- @ color     [color]  [orange]
-- @ dotheight [number] [16]
lib.registerStyle('DotDragBox', style_dotdragbox_create, nil, style_dotdragbox_draw)


-- [TEXT] Text that is printed using textplus. All textplus options work with this style.
-- This style automatically reformats: [width, height] to match the text size
-- font            [textplus_font] [nil]
-- color           [color]         [white]
-- xscale          [number]        [2]
-- yscale          [number]        [2]
-- scale           [number]        [nil]
-- limit           [number]        [nil]
-- target          [capturebuffer] [nil]
-- shader          [shader]        [nil]
-- disableAutoSize [bool]          [nil]
lib.registerStyle('Textplus', style_textplus_create, nil, style_textplus_draw)


-- [Row] A row style that is invisible. Comes with a handy debug feature
-- debug  [bool] [false]
lib.registerStyle('InviRow', style_invirow_create, nil, style_invirow_draw)


-- [Column] A column style that is invisible. Comes with a handy debug feature
-- debug  [bool] [false]
lib.registerStyle('InviColumn', style_invicolumn_create, nil, style_invicolumn_draw)


-- ============================
-- ||                        ||
-- ||         WIDGETS        ||
-- ||                        ||
-- ============================

-- Moves
local function widget_move(ui, pos)
  ui.transform:translate(vector(pos.x, pos.y, 0))
  ui:updatePosition()
end

local function widget_updateposition(ui)

  if ui.updateColl then ui:updateColl() end

  if ui.children then
    for k, child in ipairs(ui.children) do
      child:updatePosition()
    end
  end

  if ui.style.updatePosition then ui.style.updatePosition() end
end

local function updateColl(ui)
  for k, v in ipairs(ui.collList) do
    local coll = ui[v]
    local pos = coll.transform.wposition
    coll.x, coll.y = pos.x, pos.y
  end
end

local function genericCollChild(ui, name)
  local coll = Colliders.Box(ui.x, ui.y, ui.width, ui.height)

  coll.transform = Transform(vector(0, 0, 0), vector.quat(0, 0, 0), vector(1, 1, 1))
  ui.transform:addChild(coll.transform, false)

  ui.collList = ui.collList or {}
  ui.updateColl = updateColl
  table.insert(ui.collList, name)

  ui[name] = coll
end


local function genericWidget(ui, defaults)
  ui.type = defaults.type
  ui.data = {}

  if ui.active == nil then ui.active = true end

  ui.position = ui.position or vector(0, 0)

  if not ui.width then
    ui.width = defaults.width
    ui.freeWidth = true
  end

  if not ui.height then
    ui.height = defaults.height
    ui.freeHeight = true
  end

  if not ui.priority then
    ui.priority = 0
    ui.freePriority = true
  end

  -- Create the transform used for hierchy. A 3d transform is used for the sake of controlling priority
  ui.transform = Transform(vector(ui.position.x, ui.position.y, ui.priority), vector.quat(0, 0, 0), vector(1, 1, 1))

  -- Load in the style, if none provided then default it
  ui.style = ui.style or defaults.style()

  -- Built in function for each widget
  ui.tick = defaults.tick
  ui.move = widget_move
  ui.updatePosition = widget_updateposition

  -- This is an alternative to children and childrenPivot. Instead its passed as childrenAdv = {widget = ..., pivot = ...} or childrenAdv = {widget, pivot}
  if ui.childrenAdv then
    ui.children = {}
    ui.childrenPivot = {}
    for k, v in ipairs(ui.childrenAdv) do
      table.insert(ui.children, v[1] or v.widget)
      table.insert(ui.childrenPivot, v[2] or v.pivot)
    end
  end

  -- child is a shortcut for creating children entry with one field
  if ui.child then
    ui.children = {ui.child}
  end

  if ui.childPivot then
    ui.childrenPivot = {ui.childPivot}
  end

  -- this is a shorcut, if a single pivot is passed instead of a table, assume all pivots are the same
  if type(ui.childrenPivot) == "Vector2" then
    local pivot = ui.childrenPivot
    ui.childrenPivot = {}
    for i = 1, #ui.children do
      ui.childrenPivot[i] = pivot
    end
  end

  -- If not enough pivots were sent, then default to center
  if ui.children and (not ui.childrenPivot or #ui.children > #ui.childrenPivot) then
    local rem = #ui.children
    if ui.childrenPivot then
      rem = rem - #ui.childrenPivot
    else
      ui.childrenPivot = {}
    end
    for i = 1, rem do
      table.insert(ui.childrenPivot, vector(0.5, 0.5))
    end
  end

  -- Allow metatable to control these
  ui.position = nil
  ui.x = nil
  ui.y = nil
  ui.priority = nil
  ui.child = nil
  ui.childPivot = nil

  setmetatable(ui, mt)
  table.insert(widgetList, ui)
end

local function genericChildren(ui)
  for k, child in ipairs(ui.children) do
    ui.transform:addChild(child.transform)

    local sizeDiff = vector(ui.width - child.width, ui.height - child.height)
    child.transform.position = (ui.childrenPivot[k]*sizeDiff):tov3() + vector(0, 0, 0.1)
    child:updatePosition()
  end
end

local function widget_create(ui, defaults, func, container)
  ui = ui or {}
  genericWidget(ui, defaults)

  func(ui)

  if container then
    genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end


-- --------------------
-- ||      None      ||
-- --------------------

local function widget_none_tick(ui)

end

local widget_button_default = {
  type = "widget_none",
  width = 2, height = 2,
  style = lib.Style_None,
  tick = widget_none_tick,
  updatePosition = widget_none_updateposition
}

local function widget_create_none(ui)
  ui = ui or {}

  genericWidget(ui, widget_none_default)

  if ui.children then
    genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end

-- --------------------
-- ||     Button     ||
-- --------------------

local function widget_button_tick(ui)
  local cursorpos = getCursorPos(ui.sceneCoords) -- Get the position of the cursor depending on sceneCoords

  if ui.state == 'locked' then

  elseif Colliders.collide(cursorpos, ui.buttonCollider) then -- Check if the cursor is inside of the button

    -- If the cursor is being pressed or not, update the state and state timers
    if cursor.left then
      ui.state = 'held'
      ui.heldTimer = ui.heldTimer + 1
    else
      ui.state = 'selected'
      ui.selectedTimer = ui.selectedTimer + 1
    end

    -- if first frame being selected/pressed then reset timers
    if ui.state == 'held' and ui.prevstate ~= 'held' then
      ui.heldTimer = 0
    end
    if ui.state == 'selected' and ui.prevstate ~= 'selected' then
      ui.selectedTimer = 0
    end

    -- Call functions if being pressed or held
    if ui.state == 'held' and ui.prevstate ~= 'held' and ui.pressed then
      ui:pressed()
    end
    if ui.state == 'held' and ui.held then
      ui:held()
    end
  else
    -- If the cursor is not being selected, update the state and state timers
    ui.state = 'none'
    ui.releasedTimer = ui.releasedTimer + 1

    -- if first frame being released then reset timers
    if ui.prevstate ~= 'none' then
      ui.releasedTimer = 0
    end
  end

  -- Call style ticks
  if ui.style.tick then ui.style.tick(ui) end

  -- Save previous state
  ui.prevstate = ui.state
end

local widget_button_default = {
  type = "widget_button",
  width = 96, height = 32,
  style = lib.Style_RaisedButton,
  tick = widget_button_tick
}

local function widget_button_create(ui)
  ui = ui or {}

  genericWidget(ui, widget_button_default)

  ui.state = 'none'      -- Denotates what the current state is: none, selected, held
  ui.prevstate = 'none'  -- Previous state
  ui.heldTimer = 0       -- Timer: Number of frames the button has beed pressed down
  ui.selectedTimer = 0   -- Timer: Number of frames the button is selected. Not includes when held
  ui.releasedTimer = 0   -- Timer: Number of frames the button has not been interacted with

  genericCollChild(ui, "buttonCollider")

  if ui.children then
    genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end



-- -------------------
-- ||    Drag Box   ||
-- -------------------

local function widget_dragbox_tick(ui)
  local cursorpos = getCursorPos(ui.sceneCoords) -- Get the position of the cursor depending on sceneCoords

  if Colliders.collide(cursorpos, ui.dragCollider) then -- Check if the cursor is inside of the button

    -- If the cursor is being pressed or not, update the state and state timers
    if (ui.state == 'held' and cursor.left) or cursor.click then
      ui.state = 'held'
      ui.heldTimer = ui.heldTimer + 1
    else
      ui.state = 'selected'
      ui.selectedTimer = ui.selectedTimer + 1
    end

    -- if first frame being selected/pressed then reset timers
    if ui.state == 'held' and ui.prevstate ~= 'held' then
      ui.heldTimer = 0
    end
    if ui.state == 'selected' and ui.prevstate ~= 'selected' then
      ui.selectedTimer = 0
    end

  else
    if ui.state == 'none' then
      -- If the cursor is not being selected, update the state and state timers
      ui.releasedTimer = ui.releasedTimer + 1

      -- if first frame being released then reset timers
      if ui.prevstate ~= 'none' then
        ui.releasedTimer = 0
      end
    else
      if not cursor.left or ui.state == 'selected' then
        ui.state = 'none'
      end
    end
  end

  if ui.state == 'held' then
    -- When the widget is in held state, it needs to move as the cursor moves
    ui:move(vector(cursor.speedX, cursor.speedY))
  else
    -- Quality check to prevent the dragbox from going offscreen
    if not ui.sceneCoords and not ui.disableSnap then
      local newX = math.clamp(ui.dragCollider.x, -ui.dragCollider.width + 16, 800 - 16)
      local newY = math.clamp(ui.dragCollider.y, -ui.dragCollider.height + 16, 600 - 16)

      if newX ~= ui.dragCollider.x or newY ~= ui.dragCollider.y then
        ui:move(vector(newX - ui.dragCollider.x, newY - ui.dragCollider.y))
      end
    end
  end


  -- Call style ticks
  if ui.style.tick then ui.style.tick(ui) end

  -- Save previous state
  ui.prevstate = ui.state
end

local widget_dragbox_default = {
  type = "widget_dragbox",
  width = 128, height = 128,
  style = lib.Style_DotDragBox,
  tick = widget_dragbox_tick
}

function widget_dragbox_create(ui)
  ui = ui or {}

  genericWidget(ui, widget_dragbox_default)

  ui.state = 'none'      -- Denotates what the current state is: none, selected, held
  ui.prevstate = 'none'  -- Previous state
  ui.heldTimer = 0       -- Timer: Number of frames the button has beed pressed down
  ui.selectedTimer = 0   -- Timer: Number of frames the button is selected. Not includes when held
  ui.releasedTimer = 0   -- Timer: Number of frames the button has not been interacted with

  genericCollChild(ui, "dragCollider")

  if ui.children then
    genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end



-- -------------------
-- ||      TEXT     ||
-- -------------------

local function widget_text_tick(ui)
  -- Call style ticks
  if ui.style.tick then ui.style.tick(ui) end
end

local widget_text_default = {
  type = "widget_text",
  width = 32, height = 32,
  style = lib.Style_Textplus,
  tick = widget_text_tick
}

local function widget_text_create(ui)
  ui = ui or {}

  genericWidget(ui, widget_text_default)

  ui.text = ui.text or ""

  if ui.children then
    genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end




-- --------------------
-- ||       Row      ||
-- --------------------

local function widget_row_tick(ui)
  -- Call style ticks
  if ui.style.tick then ui.style.tick(ui) end
end

local widget_row_default = {
  type = "widget_row",
  width = 100, height = 100,
  style = lib.Style_InviRow,
  tick = widget_row_tick
}

function widget_row_create(ui)
  ui = ui or {}

  genericWidget(ui, widget_row_default)

  if ui.children then
    local boxSize = vector(0, ui.height/(#ui.children), 0)

    for k, child in ipairs(ui.children) do
      ui.transform:addChild(child.transform)

      local sizeDiff = vector(ui.width - child.width, boxSize.y - child.height)
      child.transform.position = (ui.childrenPivot[k]*sizeDiff):tov3() + vector(0, 0, 0.1)
      child.transform.position = child.transform.position + boxSize*(k-1)
      child:updatePosition()
    end
    -- genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end



-- -----------------------
-- ||       Column      ||
-- -----------------------

local function widget_column_tick(ui)
  -- Call style ticks
  if ui.style.tick then ui.style.tick(ui) end
end

local widget_column_default = {
  type = "widget_column",
  width = 100, height = 100,
  style = lib.Style_InviColumn,
  tick = widget_column_tick
}

function widget_column_create(ui)
  ui = ui or {}

  genericWidget(ui, widget_column_default)

  if ui.children then
    local boxSize = vector(ui.width/(#ui.children), 0, 0)

    for k, child in ipairs(ui.children) do
      ui.transform:addChild(child.transform)

      local sizeDiff = vector(boxSize.x - child.width, ui.height - child.height)
      child.transform.position = (ui.childrenPivot[k]*sizeDiff):tov3() + vector(0, 0, 0.1)
      child.transform.position = child.transform.position + boxSize*(k-1)
      child:updatePosition()
    end
    -- genericChildren(ui)
  end

  if ui.style.create then ui.style.create(ui) end

  return ui
end


-- -----------------------
-- ||       SLIDER      ||
-- -----------------------

local function widget_slider_tick(ui)
  local cursorpos = getCursorPos(ui.sceneCoords) -- Get the position of the cursor depending on sceneCoords

  if Colliders.collide(cursorpos, ui.dragCollider) then -- Check if the cursor is inside of the button

    -- If the cursor is being pressed or not, update the state and state timers
    if (ui.state == 'held' and cursor.left) or cursor.click then
      ui.state = 'held'
      ui.heldTimer = ui.heldTimer + 1
    else
      ui.state = 'selected'
      ui.selectedTimer = ui.selectedTimer + 1
    end

    -- if first frame being selected/pressed then reset timers
    if ui.state == 'held' and ui.prevstate ~= 'held' then
      ui.heldTimer = 0
    end
    if ui.state == 'selected' and ui.prevstate ~= 'selected' then
      ui.selectedTimer = 0
    end

  else
    if ui.state == 'none' then
      -- If the cursor is not being selected, update the state and state timers
      ui.releasedTimer = ui.releasedTimer + 1

      -- if first frame being released then reset timers
      if ui.prevstate ~= 'none' then
        ui.releasedTimer = 0
      end
    else
      if not cursor.left or ui.state == 'selected' then
        ui.state = 'none'
      end
    end
  end

  if ui.state == 'held' then
    -- When the widget is in held state, it needs to move as the cursor moves
    ui:move(vector(cursor.speedX, cursor.speedY))
  else
    -- Quality check to prevent the dragbox from going offscreen
    if not ui.sceneCoords and not ui.disableSnap then
      local newX = math.clamp(ui.dragCollider.x, -ui.dragCollider.width + 16, 800 - 16)
      local newY = math.clamp(ui.dragCollider.y, -ui.dragCollider.height + 16, 600 - 16)

      if newX ~= ui.dragCollider.x or newY ~= ui.dragCollider.y then
        ui:move(vector(newX - ui.dragCollider.x, newY - ui.dragCollider.y))
      end
    end
  end


  -- Call style ticks
  if ui.style.tick then ui.style.tick(ui) end
end

local widget_column_default = {
  type = "widget_slider",
  width = 100, height = 100,
  style = lib.Style_VerticalSlider,
  tick = widget_slider_tick
}

function widget_slider_create(ui)
  ui = ui or {}

  genericWidget(ui, widget_column_default)

  ui.value = ui.value or 0 -- The current value of the slider

  ui.sliderStart = Transform(vector(0, 0, 0), vector.quat(0, 0, 0), vector(1, 1, 1))
  ui.sliderStop = Transform(vector(ui.width, 0, 0), vector.quat(0, 0, 0), vector(1, 1, 1))
  genericCollChild(ui, "sliderCollider")

  ui.state = 'none'      -- Denotates what the current state is: none, selected, held
  ui.prevstate = 'none'  -- Previous state
  ui.heldTimer = 0       -- Timer: Number of frames the button has beed pressed down
  ui.selectedTimer = 0   -- Timer: Number of frames the button is selected. Not includes when held
  ui.releasedTimer = 0   -- Timer: Number of frames the button has not been interacted with

  genericChildren(ui)

  if ui.style.create then ui.style.create(ui) end

  return ui
end


-- [[======================]]
-- ||     CONSTRUCTORS     ||
-- [[======================]]

function lib.registerWidget(name, func)
  if lib[name] then
    Misc.warn('Ovelap in widget name: '..name..". Please use a different name")
  end

  lib[name] = func
end

-- All widgets have:

-- position      [vector2]
-- width         [number]
-- height        [number]
-- priority      [number]
-- sceneCoords   [bool]
-- style         [style]

-- /Use one of the followoing/
-- /A/
-- children
-- childrenPivot

-- /B/
-- child
-- childPivot

-- /C/
-- childrenAdv


lib.registerWidget('None', widget_none_create)

-- Creates a Button widget. An action is taken when the button is pressed
-- @ position     [vector2]    The position of the button
-- @ pressed      [function]   Function to call when button is pressed.
-- @ held         [number]     Function to call when the button is held. The function is called every frame
-- @ width        [number]     The width of the button
-- @ height       [number]     The height of the button
-- @ child        [widget]     Child widget that will be contained inside ofn the button
-- @ childPivot   [vector2]
-- @ sceneCoords  [bool]       Set to true to enable sceneCoords mode
-- @ priority     [number]     Priority used for rendering
lib.registerWidget('Button', widget_button_create)

-- Creates a LineEdit widget. Text can be
-- @ func   [function]
-- @ width  [number]
-- @ height [number]
function lib.lineEdit(args)
end

-- Creates a Text widget
-- @ text   [string]
lib.registerWidget('Text', widget_text_create)

-- Creates an Image widget.
-- @ texture      [luaImageResource]
-- @ width        [number]
-- @ height       [number]
-- @ sourceX      [number]
-- @ sourceY      [number]
-- @ sourceWidth  [number]
-- @ sourceHeight [number]
-- @ color        [color]
-- function lib.Image(args)
-- end

-- function lib.SpinBox(args)
-- end

-- function lib.ListBox(args)
-- end

-- function lib.TextBox(args)
-- end

-- function lib.ScrollBar(args)
-- end

-- Creates a DragBox widget. A window that can be dragged around.
-- @ position    [vector2]
-- @ width       [number]
-- @ height      [number]
-- @ sceneCoords [bool]
-- @ priority    [number]
-- @ child       [widget]
-- @ childPivot  [vector2]
lib.registerWidget('DragBox', widget_dragbox_create)

-- Creates a container meant to sort widgets into columns
-- @ width    [number]
-- @ height   [number]
-- @ children [table|widgets]
lib.registerWidget('Column', widget_column_create)

-- Creates a container meant to sort widgets into rows
-- @ width    [number]
-- @ height   [number]
-- @ children [table|widgets]
lib.registerWidget('Row', widget_row_create)

-- function lib.Grid(args)
-- end

-- function lib.SomeThingThatLetsYouPutWidgetsWhereYouWantButICantThinkOfAName(args)
-- end

-- function lib.RowList(args)
-- end





-- ============================
-- ||                        ||
-- ||     IMPLEMENTATION     ||
-- ||                        ||
-- ============================

function lib.onTick()
  for k, v in ipairs(widgetList) do
    if v.active then
      v:tick()
    end
  end
end

function lib.onDraw()
  for k, v in ipairs(widgetList) do
    if v.active and v.style.draw then
      v.style.draw(v)
    end
  end

  if buffer.debug then
    local s = " "
    if lunatime.tick() % 40 < 20 then
      s = "|"
    end
    textplus.print{text = string_insert(buffer.value, s, buffer.position), x = 8, y = 600, xscale = 2, yscale = 2, pivot = {0, 1}}
  end
end


function lib.onKeyboardPressDirect(id, repeating)
  if buffer.active then
    local value = buffer.value

    buffer.position = math.clamp(buffer.position, 0, #value)


    -- Backspace
    if id == 8 then
      value = string_remove(value, buffer.position)
      buffer.position = buffer.position - 1
      -- Delete
    elseif id == 46 then
      value = string_remove(value, buffer.position + 1)
      -- Left
    elseif id == 37 then
      buffer.position = math.clamp(buffer.position - 1, 0, #value)
      -- Right
    elseif id == 39 then
    buffer.position = math.clamp(buffer.position + 1, 0, #value)
    -- Everything else
    elseif buffer.filter(id) then
      local text = char(id)
      value = string_insert(value, text, buffer.position)
      buffer.position = buffer.position + #text
    end

    buffer.value = value
  end
end

function lib.onInitAPI()
  registerEvent(lib, "onTick", "onTick")
  registerEvent(lib, "onDraw", "onDraw")
  registerEvent(lib, "onKeyboardPressDirect", "onKeyboardPressDirect")
end

return lib
