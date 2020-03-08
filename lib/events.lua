local Events = {}

local function pointInBase( x, y)
  -- local vertices = global.Mod.PanopticonRadarCoords
  local points = global.Mod.PanopticonRadarCoords
	
  -- for i=1, #vertices-1, 2 do
  --   points[#points+1] = { x=vertices[i], y=vertices[i+1] }
  -- end

  local i, j = #points, #points
  local inside = false

  for i=1, #points do
    if ((points[i].y < y and points[j].y>=y or points[j].y< y and points[i].y>=y) and (points[i].x<=x or points[j].x<=x)) then
      if (points[i].x+(y-points[i].y)/(points[j].y-points[i].y)*(points[j].x-points[i].x)<x) then
        inside = not inside
      end
    end
    j = i
  end

  return inside
end

local function _addRadar(list, radar)
  local found = False
  for k,v in ipairs(global.Mod.PanopticonRadarCoords) do
    if v == radar.position then
      found = True
    end
  end
  if not found then
    if radar.position.x < global.Mod.PanopticonWest then
      global.Mod.PanopticonWest = radar.position.x
    end
    if radar.position.x > global.Mod.PanopticonEast then
      global.Mod.PanopticonEast = radar.position.x
    end
    if radar.position.y < global.Mod.PanopticonNorth then
      global.Mod.PanopticonNorth = radar.position.y
    end
    if radar.position.y > global.Mod.PanopticonSouth then
      global.Mod.PanopticonSouth = radar.position.y
    end
    log(string.format("Added: %d, %d", radar.position.x, radar.position.y))
    log(string.format("New N/S/E/W Max Coords: %d, %d, %d, %d", global.Mod.PanopticonNorth, global.Mod.PanopticonSouth, global.Mod.PanopticonEast, global.Mod.PanopticonWest))
    table.insert(list, radar.position)
  end
end


function Events.findall_radars()
  global.Mod.PanopticonRadarCoords = {}

  for chunk in game.surfaces.nauvis.get_chunks() do
    local top, left = chunk.x * 32, chunk.y * 32
    local bottom, right = top + 32, left + 32
    for _, radar in pairs(game.surfaces.nauvis.find_entities_filtered{area = {{top, left}, {bottom, right}}, name ="radar"}) do

      _addRadar(global.Mod.PanopticonRadarCoords, radar)

    end
  end
end


function Events.rechart_base()
  log("Recharting...")
  -- log(string.format("N/S/E/W Max Coords: %d, %d, %d, %d", global.Mod.PanopticonNorth, global.Mod.PanopticonSouth, global.Mod.PanopticonEast, global.Mod.PanopticonWest))
  local surf = game.surfaces.nauvis
  
  for chunk in surf.get_chunks() do
    local left, top = (chunk.x * 32) + 16, (chunk.y * 32) + 16
    if (top > global.Mod.PanopticonNorth) and (top < global.Mod.PanopticonSouth) and 
       (left > global.Mod.PanopticonWest) and (left < global.Mod.PanopticonEast) then
      log(string.format("Chunk %d, %d inside boundary <%d, %d - %d, %d>", left, top, global.Mod.PanopticonWest, global.Mod.PanopticonNorth, global.Mod.PanopticonEast, global.Mod.PanopticonSouth))
      if pointInBase(left, top) then
        log("Recharting chunk: " .. left .. ", " .. top)
        game.forces['player'].chart(surf, {{x = left - 16, y = top - 16}, {x = left + 16, y = top + 16}})
      end
    end
  end
end 

function Events.AddRadar(e)
  log("Adding: " .. serpent.block(e.created_entity.name))

  if e.created_entity ~= nil and e.created_entity.name == "radar" then
    radar = e.created_entity
    _addRadar(global.Mod.PanopticonRadarCoords, radar)
  end
end

function Events.AddClonedRadar(e)
  log("Adding: " .. serpent.block(e.destination.name))

  if e.destination ~= nil and e.destination.name == "radar" then
    radar = e.destination
    _addRadar(global.Mod.PanopticonRadarCoords, radar)
  end
end

function Events.RemoveRadar(e)
  log("Removing: " .. serpent.block(e.entity.name))
  if e.entity ~= nil and e.entity.name == "radar" then
    for k, v in ipairs(global.Mod.PanopticonRadarCoords) do
      if v == e.entity.position then
        table.remove(global.Mod.PanopticonRadarCoords, k)
      end
    end
  end
end

function Events.Init (e)
  log("Interval: " .. global.Mod.PanopticonRechartInterval)
  script.on_nth_tick((global.Mod.PanopticonRechartInterval * 60), Events.rechart_base)
end

return Events
