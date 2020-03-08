require("commands")
local Events = require("lib.events")

local function CreateGlobals()
  global.Mod = global.Mod or {}
  global.Mod.North = global.Mod.North or 0
  global.Mod.East = global.Mod.East or 0
  global.Mod.South = global.Mod.South or 0
  global.Mod.West = global.Mod.West or 0
  global.Mod.RadarCoords = global.Mod.RadarCoords or {}
  global.Mod.BaseCandidates = global.Mod.BaseCandidates or {}
  global.Mod.RechartInterval = global.Mod.RechartInterval or 30
end

local function GetStartUpSettings()
  global.Mod.RechartInterval = settings.global['panopticon-rechart-interval'].value
end

local function UpdateSetting(settingName)
  if settingName == "panopticon-rechart-interval" then
    global.Mod.RechartInterval = settings.global['panopticon-rechart-interval'].value
    -- Events.findall_radars()
    script.on_nth_tick(nil)
    script.on_nth_tick((global.Mod.RechartInterval * 60), Events.rechart_base)
    Events.rechart_base()

  end
end

local function OnStartup()
  CreateGlobals()
  GetStartUpSettings()
  -- Events.findall_radars()
  Events.Init()
end

local function OnSettingChanged(event)
  UpdateSetting(event.setting)
  Events.Init()
end

local function OnLoad()
  Events.Init()
end

script.on_init(OnStartup)
script.on_load(OnLoad)
script.on_configuration_changed(OnStartup)

script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)

script.on_event(defines.events.on_built_entity, Events.AddRadar, { {filter = "name", name = "radar"} })
script.on_event(defines.events.on_robot_built_entity, Events.AddRadar, { {filter = "name", name = "radar"} })
script.on_event(defines.events.on_entity_died, Events.RemoveRadar, { {filter = "name", name = "radar"} })
script.on_event(defines.events.on_player_mined_entity, Events.RemoveRadar, { {filter = "name", name = "radar"} })
script.on_event(defines.events.on_robot_mined_entity, Events.RemoveRadar, { {filter = "name", name = "radar"} })
script.on_event(defines.events.on_entity_cloned, Events.AddClonedRadar, { {filter = "name", name = "radar"} })