local Events = require("lib.events")

local function CreateGlobals()
  if global.Mod == nil then
    global.Mod = {}
  end

  if global.Mod.PanopticonNorth == nil then
    global.Mod.PanopticonNorth = 0
  end

  if global.Mod.PanopticonEast == nil then
    global.Mod.PanopticonEast = 0
  end

  if global.Mod.PanopticonSouth == nil then
    global.Mod.PanopticonSouth = 0
  end

  if global.Mod.PanopticonWest == nil then
    global.Mod.PanopticonWest = 0
  end

  if global.Mod.PanopticonRadarCoords == nil then
    global.Mod.PanopticonRadarCoords = {}
  end

  if global.Mod.PanopticonRechartInterval == nil then
    global.Mod.PanopticonRechartInterval = 30
  end
end

local function GetStartUpSettings()
  global.Mod.PanopticonRechartInterval = settings.global['panopticon-rechart-interval'].value
end

local function UpdateSetting(settingName)
  if settingName == "panopticon-rechart-interval" then
    global.Mod.PanopticonRechartInterval = settings.global['panopticon-rechart-interval'].value
    script.on_nth_tick(nil, Events.rechart_base)
    Events.findall_radars()
    script.on_nth_tick((global.Mod.PanopticonRechartInterval * 60), events.rechart_base)

  end
end

local function OnStartup()
  CreateGlobals()
  GetStartUpSettings()
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