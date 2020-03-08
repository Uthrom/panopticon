local trig = require("lib.trig")
local Events = {}

local function _findBaseCandidates()
	local surf = game.surfaces.nauvis
	global.Mod.BaseCandidates = {}

	for chunk in surf.get_chunks() do
	  local left, top = (chunk.x * 32) + 16, (chunk.y * 32) + 16
	  if (top > global.Mod.North) and (top < global.Mod.South) and 
		 (left > global.Mod.West) and (left < global.Mod.East) then
		if trig.PointWithinShape(global.Mod.RadarCoords, left, top) then
			table.insert(global.Mod.BaseCandidates, {x = left, y = top })
		end
	  end
	end
	log(string.format("Base Candidates: %d chunks.", #global.Mod.BaseCandidates))
end

local function _addRadar(list, radar)
  local found = False
  for k,v in ipairs(global.Mod.RadarCoords) do
    if v == radar.position then
      found = True
    end
  end
  if not found then
    if radar.position.x < global.Mod.West then
      global.Mod.West = radar.position.x
    end
    if radar.position.x > global.Mod.East then
      global.Mod.East = radar.position.x
    end
    if radar.position.y < global.Mod.North then
      global.Mod.North = radar.position.y
    end
    if radar.position.y > global.Mod.South then
      global.Mod.South = radar.position.y
    end
    log(string.format("Added: %d, %d", radar.position.x, radar.position.y))
    log(string.format("New N/S/E/W Max Coords: %d, %d, %d, %d", global.Mod.North, global.Mod.South, global.Mod.East, global.Mod.West))
	table.insert(list, radar.position)
  end
end

function Events.findall_radars()
  global.Mod.RadarCoords = {}

  for chunk in game.surfaces.nauvis.get_chunks() do
    local top, left = chunk.x * 32, chunk.y * 32
    local bottom, right = top + 32, left + 32
    for _, radar in pairs(game.surfaces.nauvis.find_entities_filtered{area = {{top, left}, {bottom, right}}, name ="radar"}) do

      _addRadar(global.Mod.RadarCoords, radar)
    end
  end
  _findBaseCandidates()
end

function Events.rechart_base()
  log("Recharting...")
  local nChunks = 0
  local tChunks = 0
  local surf = game.surfaces.nauvis
  
  for k, v in pairs(global.Mod.BaseCandidates) do
	game.forces['player'].chart(surf, {{x = v.x - 16, y = v.y - 16}, {x = v.x + 16, y = v.y + 16}})
	nChunks = nChunks + 1
  end
  log(string.format("Recharted %d chunks.", nChunks))
end 

function Events.AddRadar(e)
  if e.created_entity ~= nil and e.created_entity.name == "radar" then
    radar = e.created_entity
	  _addRadar(global.Mod.RadarCoords, radar)
	  _findBaseCandidates()
  end
end

function Events.AddClonedRadar(e)
  if e.destination ~= nil and e.destination.name == "radar" then
    radar = e.destination
	  _addRadar(global.Mod.RadarCoords, radar)
	  _findBaseCandidates()
  end
end

function Events.RemoveRadar(e)
  log("Removing: " .. serpent.block(e.entity.name))
  if e.entity ~= nil and e.entity.name == "radar" then
    for k, v in ipairs(global.Mod.RadarCoords) do
      if v == e.entity.position then
        table.remove(global.Mod.RadarCoords, k)
      end
	end
	_findBaseCandidates()
  end
end

function Events.Init (e)
  log("Interval: " .. global.Mod.RechartInterval)
  script.on_nth_tick((global.Mod.RechartInterval * 60), Events.rechart_base)
end

return Events
