local addonName, addon = ...
local L = addon.L
local LOOT_ROLL_TYPE_PASS = _G.LOOT_ROLL_TYPE_PASS or 0
local LOOT_ROLL_TYPE_NEED = _G.LOOT_ROLL_TYPE_NEED or 1
local LOOT_ROLL_TYPE_GREED = _G.LOOT_ROLL_TYPE_GREED or 2
local LOOT_ROLL_TYPE_DISENCHANT = _G.LOOT_ROLL_TYPE_DISENCHANT or 3
local NET_UPDATES, CONFIRM_RETRY = 5, 0.015625
local After = C_Timer.After
local Ticker = C_Timer.NewTicker
local tremove = table.remove
local math_ceil = math.ceil
local partyUnit, raidUnit = { }, { }
do
  for i=1,MAX_PARTY_MEMBERS do
    partyUnit[i] = "party"..i
  end
  for i=1,MAX_RAID_MEMBERS do
    raidUnit[i] = "raid"..i
  end
end

local LagMonitor,NetStats
NetStats = function()
  if not AutoRollNConfirmDBC.smartdelay then
    if LagMonitor.roundtrip then
      LagMonitor.roundtrip = nil
    end
    return
  end
  local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
  local latency = latencyHome > latencyWorld and latencyHome or latencyWorld
  LagMonitor.roundtrip = (math_ceil(latency * 3))/1000 -- convert to sec for timers
end
LagMonitor = C_FunctionContainers.CreateCallback(NetStats)
Ticker(NET_UPDATES,LagMonitor)

local DelayConfirm, ConfirmBind
ConfirmBind = function()
  if DelayConfirm.slots then
    local slot = tremove(DelayConfirm.slots,1)
    if slot then
      ConfirmLootSlot(slot)
      local dialog = StaticPopup_FindVisible("LOOT_BIND")
      if dialog then
        dialog:GetButton1():Click()
      end
    end
    slot = DelayConfirm.slots[1]
    if slot then
      After((LagMonitor.roundtrip or CONFIRM_RETRY), DelayConfirm)
    end
  end
end
DelayConfirm = C_FunctionContainers.CreateCallback(ConfirmBind)

local DelayAutoRollConfirm, ConfirmAutoRoll
ConfirmAutoRoll = function()
  if DelayAutoRollConfirm.rolls then
    local rollID = tremove(DelayAutoRollConfirm.rolls,1)
    if rollID then
      ConfirmLootRoll(rollID,AutoRollNConfirmDBC.roll)
      local dialog = StaticPopup_FindVisible("CONFIRM_LOOT_ROLL")
      if dialog then
        dialog:GetButton1():Click()
      end
    end
    rollID = DelayAutoRollConfirm.rolls[1]
    if rollID then
      After((LagMonitor.roundtrip or CONFIRM_RETRY), DelayAutoRollConfirm)
    end
  end
end
DelayAutoRollConfirm = C_FunctionContainers.CreateCallback(ConfirmAutoRoll)

addon.events = CreateFrame("Frame")
addon.OnEvent = function(self,event,...)
  return addon[event] and addon[event](addon,event,...)
end
addon.events:SetScript("OnEvent", addon.OnEvent)
function addon:RegisterEvent(event)
  if C_EventUtils.IsEventValid(event) then
    addon.events:RegisterEvent(event)
  end
end
function addon:UnregisterEvent(event)
  if C_EventUtils.IsEventValid(event) then
    if addon.events:IsEventRegistered(event) then
      addon.events:UnregisterEvent(event)
    end
  end
end
function addon:IsEventRegistered(event)
  if C_EventUtils.IsEventValid(event) then
    return addon.events:IsEventRegistered(event)
  end
end
function addon:RegisterUnitEvent(event,unit)
  if C_EventUtils.IsEventValid(event) then
    addon.events:RegisterUnitEvent(event,unit)
  end
end
addon:RegisterEvent("LOOT_BIND_CONFIRM")
addon:RegisterEvent("START_LOOT_ROLL")
addon:RegisterEvent("CONFIRM_LOOT_ROLL")
addon:RegisterEvent("ADDON_LOADED")

local defaults = {
  roll = LOOT_ROLL_TYPE_GREED,
  smartdelay = true,
}
function addon:ADDON_LOADED(event,...)
  if ... == addonName then
    AutoRollNConfirmDBC = AutoRollNConfirmDBC or {}
    for k,v in pairs(defaults) do
      if AutoRollNConfirmDBC[k] == nil then
        AutoRollNConfirmDBC[k] = v
      end
    end
    addon:CreateSettings()
  end
end

local function SoloLooting()
  if GetNumGroupMembers() < 2 then
    return true
  else
    if IsInRaid() then
      for i=1,MAX_RAID_MEMBERS do
        local unit = raidUnit[i]
        if UnitExists(unit) and not UnitIsUnit("player",unit) then
          if UnitIsConnected(unit) and UnitIsVisible(unit) and UnitInPhase(unit) then
            return
          end
        end
      end
    elseif IsInGroup() then
      for i=1,MAX_PARTY_MEMBERS do
        local unit = partyUnit[i]
        if UnitIsConnected(unit) and UnitIsVisible(unit) and UnitInPhase(unit) then
          return
        end
      end
    end
    return true
  end
end

function addon:LOOT_BIND_CONFIRM(event,...)
  if SoloLooting() then
    self:AutoConfirm(...)
  end
end

function addon:START_LOOT_ROLL(event,...)
  local rollID, rollTime, lootHandle = ...
  local texture, name, count, quality, bindOnPickUp, canNeed, canGreed = GetLootRollItemInfo(rollID)
  if not (name and canGreed) then return end
  if SoloLooting() then
    self:AutoRoll(rollID)
  end
end

function addon:CONFIRM_LOOT_ROLL(event,...)
  if SoloLooting() then
    self:AutoConfirmRoll(...)
  end
end

function addon:AutoConfirm(...)
  local slot = ...
  slot = tonumber(slot)
  if not slot then return end
  local texture, item, quantity, currencyID, quality, locked = GetLootSlotInfo(slot)
  if texture and not locked then
    DelayConfirm.slots = DelayConfirm.slots or {}
    DelayConfirm.slots[#DelayConfirm.slots+1] = slot
    After((LagMonitor.roundtrip or CONFIRM_RETRY), DelayConfirm)
  end
end

function addon:AutoConfirmRoll(...)
  local rollID, rollType, confirmReason = ...
  if rollID and rollType and rollType == AutoRollNConfirmDBC.roll then
    DelayAutoRollConfirm.rolls = DelayAutoRollConfirm.rolls or {}
    DelayAutoRollConfirm.rolls[#DelayAutoRollConfirm.rolls+1] = rollID
    After((LagMonitor.roundtrip or CONFIRM_RETRY), DelayAutoRollConfirm)
  end
end

function addon:AutoRoll(rollID)
  RollOnLoot(rollID,AutoRollNConfirmDBC.roll)
end