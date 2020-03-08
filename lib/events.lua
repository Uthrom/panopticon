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

function Events.findall_radars()
  global.Mod.PanopticonRadarCoords = {}

  for chunk in game.surfaces.nauvis.get_chunks() do
    local top, left = chunk.x * 32, chunk.y * 32
    local bottom, right = top + 32, left + 32
    for _, radar in pairs(game.surfaces.nauvis.find_entities_filtered{area = {{top, left}, {bottom, right}}, force="player", name ="radar"}) do
      if radar.status == defines.entity_status.working then
          
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

        log(string.format("New N/S/E/W Coords: %d, %d, %d, %d", global.Mod.PanopticonNorth, global.Mod.PanopticonSouth, global.Mod.PanopticonEast, global.Mod.PanopticonWest))

        table.insert(global.Mod.PanopticonRadarCoords, radar.position)
      end
    end
  end
end


function Events.rechart_base()
  log("Recharting...")
  local surf = game.surfaces.nauvis
  
  for chunk in surf.get_chunks() do
    local top, left = (chunk.x * 32) + 16, (chunk.y * 32) + 16
    if (top > global.Mod.PanopticonNorth) and (top < global.Mod.PanopticonSouth) and 
       (left > global.Mod.PanopticonWest) and (left < global.Mod.PanopticonEast) then
      if pointInBase(left, top) then
        log("Recharting chunk: " .. chunk.x .. ", " .. chunk.y )
        game.forces['player'].chart(surf, {{x = chunk.x - 16, y = chunk.y - 16}, {x = chunk.x + 16, y = chunk.y + 16}})
      end
    end
  end
end 

function Events.AddRadar(e)
  log("Adding: " .. serpent.block(e.created_entity.name))

  if e.created_entity ~= nil and e.created_entity.name == "radar" then
    radar = e.created_entity
    found = False
    for k,v in ipairs(global.Mod.PanopticonRadarCoords) do
      if v == radar.position then
        found = True
      end
    end
    if not found then
      table.insert(global.Mod.PanopticonRadarCoords, radar.position)
    end
  end
end

function Events.AddClonedRadar(e)
  log("Adding: " .. serpent.block(e.destination.name))

  if e.destination ~= nil and e.destination.name == "radar" then
    radar = e.destination
    found = False
    for k,v in ipairs(global.Mod.PanopticonRadarCoords) do
      if v == radar.position then
        found = True
      end
    end
    if not found then
      table.insert(global.Mod.PanopticonRadarCoords, radar.position)
    end
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
  Events.findall_radars()
  script.on_nth_tick((global.Mod.PanopticonRechartInterval * 60), Events.rechart_base)

end

return Events
