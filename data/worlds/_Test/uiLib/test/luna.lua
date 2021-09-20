local ui = require("ui")
local cursor = require("ui/cursor")

cursor.create()

-- ui.buffer.debug = true
-- ui.buffer.active = true

local textWidget = ui.Text{
  text = "wassup",
  style = ui.Style_Textplus{color = Color.red}
}

local button1 = ui.Button{
  width = 32, height = 32,
  style = ui.Style_RaisedButton{color = Color.red},
}

local button2 = ui.Button{
  width = 32, height = 32,
  style = ui.Style_RaisedButton{color = Color.orange},
}

local button3 = ui.Button{
  width = 32, height = 32,
  style = ui.Style_RaisedButton{color = Color.yellow},
}

local button4 = ui.Button{
  width = 32, height = 32,
  style = ui.Style_RaisedButton{color = Color.green},
}

local button5 = ui.Button{
  width = 32, height = 32,
  style = ui.Style_RaisedButton{color = Color.blue},
}

local button6 = ui.Button{
  width = 32, height = 32,
  style = ui.Style_RaisedButton{color = Color.purple},
}


local buttonHopWidget = ui.Button{
  child = textWidget, childPivot = vector(0.5, 0.5),
  position = vector(200, 200), width = 96, height = 32,
  -- style = ui.Style_RaisedButton{debug = true},
  held = function(widget) if widget.heldTimer == 0 then SFX.play(1) end player.speedY = -5 end,
}


local col1 = ui.Column{
  width = 400, height = 280,
  children = {button1, button2}
}

local col2 = ui.Column{
  width = 400, height = 280,
  children = {button3, button4}
}

local col3 = ui.Column{
  width = 400, height = 280,
  children = {button5, button6, buttonHopWidget}
}

local dragBoxWidget = ui.DragBox{
  child = ui.Row{children = {col1, col2, col3}, width = 400, height = 280},
  position = vector(100, 100), width = 420, height = 300,
  style = ui.Style_DotDragBox{debug = true, color = Color.brown}
}

local textWidget2 = ui.Text{
  text = "look, im text",
  position = vector(500, 500),
  style = ui.Style_Textplus{color = Color.red}
}

local butttt = ui.Button{
  child = textWidget2, childPivot = vector(0.5, 0.5),
  position = vector(200, 200), width = 120, height = 32,
  -- style = ui.Style_RaisedButton{debug = true},
  held = function(widget) if widget.heldTimer == 0 then SFX.play(1) end player.speedY = -5 end,
}

local dragBoxWidget2 = ui.DragBox{
  child = dragBoxWidget, childPivot = vector(0.5, 0.5),
  position = vector(400, 100), width = 160, height = 100, priority = 5,
  style = ui.Style_DotDragBox{}
}
-- function onStart()
-- end
--
--
-- function onTick()
-- end
--
--
-- function onDraw()
-- end
--
--
-- function onEvent(eventName)
-- end
