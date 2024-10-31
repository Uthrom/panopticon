local trig = require("lib.trig")
local Constants = require("constants")

local Events = {}

-- Helper function to ensure storage is initialized for a given surface
local function CheckSurfaceStorage(surface_name)
  storage.Mod[surface_name] = storage.Mod[surface_name] or {
    North = 0,
    East = 0,
    South = 0,
    West = 0,
    RadarCoords = {},
    BaseCandidates = {}
  }
end

local function _findBaseCandidates(surface_name)
  CheckSurfaceStorage(surface_name)
  local surf = game.surfaces[surface_name]

  storage.Mod[surface_name].BaseCandidates = {}

  -- Convert RadarCoords from dictionary to array format for PointWithinShape
  local radar_coords_array = {}
  for _, radar_position in pairs(storage.Mod[surface_name].RadarCoords) do
    table.insert(radar_coords_array, radar_position)
  end

  for chunk in surf.get_chunks() do
    local left, top = (chunk.x * 32) + 16, (chunk.y * 32) + 16
    if (top > storage.Mod[surface_name].North) and (top < storage.Mod[surface_name].South) and
        (left > storage.Mod[surface_name].West) and (left < storage.Mod[surface_name].East) then
      if trig.PointWithinShape(radar_coords_array, left, top) then
        table.insert(storage.Mod[surface_name].BaseCandidates, { x = left, y = top })
      end
    end
  end

  log(string.format("Base Candidates: %d chunks on surface %s.", #storage.Mod[surface_name].BaseCandidates, surface_name))
end
local function _addRadar(surface_name, radar)
  -- Ensure storage for the surface is initialized
  CheckSurfaceStorage(surface_name)

  -- Create a unique key for the radar's position based on its coordinates
  local position_key = radar.position.x .. "," .. radar.position.y

  -- Check if this radar position already exists in RadarCoords
  if not storage.Mod[surface_name].RadarCoords[position_key] then
    -- Update the boundary coordinates if necessary
    storage.Mod[surface_name].West = math.min(storage.Mod[surface_name].West, radar.position.x)
    storage.Mod[surface_name].East = math.max(storage.Mod[surface_name].East, radar.position.x)
    storage.Mod[surface_name].North = math.min(storage.Mod[surface_name].North, radar.position.y)
    storage.Mod[surface_name].South = math.max(storage.Mod[surface_name].South, radar.position.y)

    -- Add the radar to RadarCoords as a dictionary entry
    storage.Mod[surface_name].RadarCoords[position_key] = { x = radar.position.x, y = radar.position.y }

    -- Log the added radar and updated boundaries for debugging (optional)
    -- log(string.format("Added radar at position (%d, %d) on surface %s", radar.position.x, radar.position.y, surface_name))
    -- log(string.format("Updated boundaries on surface %s: North=%d, South=%d, East=%d, West=%d",
    --   surface_name, storage.Mod[surface_name].North, storage.Mod[surface_name].South,
    --  storage.Mod[surface_name].East, storage.Mod[surface_name].West))
  end
end

function Events.findall_radars(surface_name)
  if surface_name and type(surface_name) == "string" then

    CheckSurfaceStorage(surface_name)
    storage.Mod[surface_name].RadarCoords = {}
    for chunk in game.surfaces[surface_name].get_chunks() do
      local top, left = chunk.x * 32, chunk.y * 32
      local bottom, right = top + 32, left + 32
      for _, radar in pairs(game.surfaces[surface_name].find_entities_filtered { area = { { top, left }, { bottom, right } }, name = "radar" }) do
        _addRadar(surface_name, radar)
      end
    end
    _findBaseCandidates(surface_name)
  else
    for _, surface in pairs(game.surfaces) do
--      log("findall_radar(null) on surface " .. surface.name)
--      log("Mod surface data: " .. serpent.block(storage.Mod[surface.name]))
      Events.findall_radars(surface.name)
    end
  end
end

function Events.rechart_base(surface_name)
  if surface_name and type(surface_name) == "string" then
--    log("Recharting on surface " .. surface_name .. "...")
    local nChunks = 0
    local surf = game.surfaces[surface_name]
    serpent.block(game.surfaces[surface_name])

    for _, v in pairs(storage.Mod[surface_name].BaseCandidates) do
      game.forces['player'].chart(surf, { { x = v.x - 16, y = v.y - 16 }, { x = v.x + 16, y = v.y + 16 } })
      nChunks = nChunks + 1
    end
--    log(string.format("Recharted %d chunks on surface %s.", nChunks, surface_name))
  else
    for _, surface in pairs(game.surfaces) do
      Events.rechart_base(surface.name)
    end
  end
end

function Events.AddRadar(e)
  if e.created_entity ~= nil and e.created_entity.name == "radar" then
    local radar = e.created_entity
    local surface_name = radar.surface.name
    CheckSurfaceStorage(surface_name)
    _addRadar(surface_name, radar)
    _findBaseCandidates(surface_name)
  end
end

function Events.AddClonedRadar(e)
  if e.destination ~= nil and e.destination.name == "radar" then
    local radar = e.destination
    local surface_name = radar.surface.name
    CheckSurfaceStorage(surface_name)
    _addRadar(surface_name, radar)
    _findBaseCandidates(surface_name)
  end
end

function Events.RemoveRadar(e)
  if e.entity ~= nil and e.entity.name == "radar" then
    local surface_name = e.entity.surface.name
    CheckSurfaceStorage(surface_name)
    
    -- Create the unique key for the radar's position
    local position_key = e.entity.position.x .. "," .. e.entity.position.y
    
    -- Remove the radar from RadarCoords if it exists
    if storage.Mod[surface_name].RadarCoords[position_key] then
      storage.Mod[surface_name].RadarCoords[position_key] = nil
    end

    -- Recalculate base candidates after removing the radar
    _findBaseCandidates(surface_name)
  end
end

function Events.OnSurfaceCreated(data)
  -- Retrieve the surface using the surface_index from event data
  local surface = game.surfaces[data.surface_index]

  CheckSurfaceStorage(surface.name)
  if surface then
    -- Initialize storage.Mod for the new surface
    storage.Mod[surface.name] = storage.Mod[surface.name] or {
      North = 0,
      East = 0,
      South = 0,
      West = 0,
      RadarCoords = {},
      BaseCandidates = {}
    }
--    log(string.format("Initialized storage for new surface: %s", surface.name))

    Events.Init(surface.name)
  end
end

function Events.OnSurfaceRenamed(data)
  local old_name = data.old_name
  local new_name = data.new_name

  if storage.Mod[old_name] then
    storage.Mod[new_name] = storage.Mod[old_name]
    storage.Mod[old_name] = nil
--    log(string.format("Renamed storage for surface %s to %s", old_name, new_name))
  end
end

function Events.OnSurfaceDeleted(data)
  -- Retrieve the surface using the surface_index
  local surface = game.surfaces[data.surface_index]

  CheckSurfaceStorage(surface.name)
  if surface then
    local surface_name = surface.name
    -- Check if storage.Mod contains an entry for this surface and delete it if it exists
    if storage.Mod[surface_name] then
      storage.Mod[surface_name] = nil
--      log(string.format("Deleted storage for surface %s", surface_name))
    end
  end
end

function Events.Init()
  storage.Mod = storage.Mod or {}
  storage.Mod.RechartInterval = storage.Mod.RechartInterval or Constants.RechartInterval -- Initialize RechartInterval globally

  script.on_nth_tick((storage.Mod.RechartInterval * 60), function() Events.rechart_base() end)
end

return Events
