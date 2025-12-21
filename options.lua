local addonName, addon = ...
local L = addon.L

local LOOT_ROLL_TYPE_PASS = _G.LOOT_ROLL_TYPE_PASS or 0
local LOOT_ROLL_TYPE_NEED = _G.LOOT_ROLL_TYPE_NEED or 1
local LOOT_ROLL_TYPE_GREED = _G.LOOT_ROLL_TYPE_GREED or 2
local LOOT_ROLL_TYPE_DISENCHANT = _G.LOOT_ROLL_TYPE_DISENCHANT or 3

function addon.OnSettingChanged(setting,value)
  --[[if setting.variableKey == "varkey" and value == true then

  end]]
end

function addon:CreateSettings()
  addon._category = Settings.RegisterVerticalLayoutCategory(addonName)
  local variableTable
  do
    variableTable = AutoRollNConfirmDBC
    local name = L["Auto Roll"]
    local variable = addonName.."_AUTOROLL"
    local variableKey = "roll"
    local defaultValue = LOOT_ROLL_TYPE_GREED

    local function GetOptions()
      local container = Settings.CreateControlTextContainer()
      container:Add(LOOT_ROLL_TYPE_GREED, GREED)
      container:Add(LOOT_ROLL_TYPE_NEED, NEED)
      return container:GetData()
    end
    local setting = Settings.RegisterAddOnSetting(addon._category, variable, variableKey, variableTable, type(defaultValue), name, defaultValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    Settings.CreateDropdown(addon._category, setting, GetOptions, L["Select Auto Roll Option"])
  end
  do
    variableTable = AutoRollNConfirmDBC
    local name = L["Smart Delay"]
    local variable = addonName.."_SMARTDELAY"
    local variableKey = "smartdelay"
    local defaultValue = true
    local setting = Settings.RegisterAddOnSetting(addon._category, variable, variableKey, variableTable, type(defaultValue), name, defaultValue)
    setting:SetValueChangedCallback(addon.OnSettingChanged)
    local tooltip = L["Automatically adjust confirmation delay based on Latency"]
    Settings.CreateCheckbox(addon._category, setting, tooltip)
  end

  Settings.RegisterAddOnCategory(addon._category)
end
