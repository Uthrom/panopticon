require("commands")
local Events = require("lib.events")

local function InitializeStorage()
  storage.Mod = storage.Mod or {}
  storage.Mod.RechartInterval = storage.Mod.RechartInterval or settings.global['panopticon-rechart-interval'].value
end

local function CreateGlobals(surface_name)
  storage.Mod = storage.Mod or {}
  storage.Mod[surface_name] = storage.Mod[surface_name] or {}
  storage.Mod[surface_name].North = storage.Mod[surface_name].North or 0
  storage.Mod[surface_name].East = storage.Mod[surface_name].East or 0
  storage.Mod[surface_name].South = storage.Mod[surface_name].South or 0
  storage.Mod[surface_name].West = storage.Mod[surface_name].West or 0
  storage.Mod[surface_name].RadarCoords = storage.Mod[surface_name].RadarCoords or {}
  storage.Mod[surface_name].BaseCandidates = storage.Mod[surface_name].BaseCandidates or {}
end

local function UpdateSetting(settingName)
  if settingName == "panopticon-rechart-interval" then
    storage.Mod.RechartInterval = settings.global['panopticon-rechart-interval'].value
    -- Re-register the recharting interval
    script.on_nth_tick(nil) -- Clear previous tick events
    script.on_nth_tick((storage.Mod.RechartInterval * 60), function() Events.rechart_base() end)
    Events.rechart_base()   -- Trigger immediate rechart
  end
end

local function OnStartup()
  for _, surf in pairs(game.surfaces) do
    CreateGlobals(surf.name)
  end

  InitializeStorage() -- Initialize global settings storage
  Events.Init()       -- Initialize radar searches and rechart intervals
end

local function OnSettingChanged(event)
  UpdateSetting(event.setting)
  Events.Init()
end

local function OnLoad()
  InitializeStorage() -- Ensure storage is initialized
  Events.Init()
end

-- Event handlers
script.on_init(OnStartup)
script.on_load(OnLoad)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)

-- Entity event handlers for radars
script.on_event(defines.events.on_built_entity, Events.AddRadar, { { filter = "name", name = "radar" } })
script.on_event(defines.events.on_robot_built_entity, Events.AddRadar, { { filter = "name", name = "radar" } })
script.on_event(defines.events.on_entity_died, Events.RemoveRadar, { { filter = "name", name = "radar" } })
script.on_event(defines.events.on_player_mined_entity, Events.RemoveRadar, { { filter = "name", name = "radar" } })
script.on_event(defines.events.on_robot_mined_entity, Events.RemoveRadar, { { filter = "name", name = "radar" } })
script.on_event(defines.events.on_entity_cloned, Events.AddClonedRadar, { { filter = "name", name = "radar" } })
script.on_event(defines.events.on_surface_created, Events.OnSurfaceCreated)
script.on_event(defines.events.on_surface_imported, Events.OnSurfaceCreated)
script.on_event(defines.events.on_surface_renamed, Events.OnSurfaceRenamed)
script.on_event(defines.events.on_surface_deleted, Events.OnSurfaceDeleted)