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
