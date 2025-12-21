local addonName, addon = ...

local L = setmetatable({}, { __index = function(t, k)
  local v = tostring(k)
  rawset(t, k, v)
  return v
end })

addon.L = L

local LOCALE = GAME_LOCALE or GetLocale()