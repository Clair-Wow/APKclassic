local ADDON = ...
APK = APK or {}
local A = APK

-- =========================
-- SavedVariables & defaults
-- =========================
local defaults = {
  favorites = {},   -- [petGUID]=true
  blacklist = {},   -- [petGUID]=true
  summonCount = {}, -- [petGUID]=number
  lastSummonedGUID = nil,
  settings = {
    autoOnLogin = true,
    autoOnDismount = true,
    allowIndoors = false,
    allowOutdoors = true,
    allowInRaid = false,
    randomMode = "ANY", -- ANY | FLYING | NONFLYING
    useFavoritesForAuto = true,
    buttonLocked = false,
    buttonPoint = { "CENTER", "UIParent", "CENTER", 0, -120 },

    -- Minimap
    minimap = { show = true, angle = 210, radius = 115 },

    -- Zone sets
    zoneMode = false, -- if true, use zone set when available
    zoneSets = {},    -- [mapID] = { [guid]=true, ... }
  },
}

local function copyDefaults(src, dest)
  if type(dest) ~= "table" then dest = {} end
  for k, v in pairs(src) do
    if type(v) == "table" then
      dest[k] = copyDefaults(v, dest[k])
    elseif dest[k] == nil then
      dest[k] = v
    end
  end
  return dest
end

local function S() return APKDB.settings end
local function isFav(guid) return APKDB.favorites[guid] end
local function isBlk(guid) return APKDB.blacklist[guid] end

-- =========================
-- Helpers (Classic-safe)
-- =========================
local PET_TYPE_FLYING = 3 -- Battle-pet family "Flying"

-- Some Classic builds don’t expose IsIndoors(); guard it.
local function SafeIsIndoors()
  if type(IsIndoors) == "function" then return IsIndoors() end
  -- Fallback heuristic: treat instances as indoors if function missing.
  local inInstance = IsInInstance and IsInInstance()
  return (inInstance == "party" or inInstance == "raid" or inInstance == "pvp" or inInstance == "arena") and true or nil
end

local function AllowedByLocation()
  if IsInRaid and IsInRaid() and not S().allowInRaid then return false, "raid" end
  local indoors = SafeIsIndoors()
  if indoors == true and not S().allowIndoors then return false, "indoors" end
  if indoors == false and not S().allowOutdoors then return false, "outdoors" end
  return true
end

local function CanSummonNow()
  if InCombatLockdown and InCombatLockdown() then return false, "combat" end
  if C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then
    return false, "pet battle"
  end
  return true
end

local function ModePass(petType, mode)
  if mode == "FLYING" then return petType == PET_TYPE_FLYING end
  if mode == "NONFLYING" then return petType ~= PET_TYPE_FLYING end
  return true
end

local function AddToPoolIfEligible(pool, guid, petType, onlyFav, mode)
  if isBlk(guid) then return end
  if onlyFav and not isFav(guid) then return end
  if not ModePass(petType, mode) then return end
  if C_PetJournal.PetIsSummonable and not C_PetJournal.PetIsSummonable(guid) then return end
  pool[#pool + 1] = guid
end

-- Build pool from a GUID=>true set
local function BuildPoolFromSet(setTbl, onlyFav, mode)
  local pool = {}
  if not setTbl then return pool end
  for guid in pairs(setTbl) do
    local _, _, owned, _, _, _, _, _, _, petType = C_PetJournal.GetPetInfoByPetID(guid)
    if owned then AddToPoolIfEligible(pool, guid, petType, onlyFav, mode) end
  end
  return pool
end

-- Build pool from entire collection
local function BuildPoolFromCollection(onlyFav, mode)
  local pool = {}
  local n = C_PetJournal.GetNumPets()
  for i = 1, n do
    local guid, _, owned, _, _, _, _, _, _, petType = C_PetJournal.GetPetInfoByIndex(i)
    if owned and guid then AddToPoolIfEligible(pool, guid, petType, onlyFav, mode) end
  end
  return pool
end

local function RandPick(t)
  if #t == 0 then return nil end
  return t[math.random(#t)]
end

local function IncrementCount(guid)
  APKDB.summonCount[guid] = (APKDB.summonCount[guid] or 0) + 1
  APKDB.lastSummonedGUID = guid
end

local function SummonGUID(guid)
  if not guid then return end
  if C_PetJournal.PetIsSummonable and not C_PetJournal.PetIsSummonable(guid) then
    A:Notify("That pet can't be summoned right now.")
    return
  end
  C_PetJournal.SummonPetByGUID(guid)
  IncrementCount(guid)
  local _, _, _, _, _, _, _, speciesName, icon = C_PetJournal.GetPetInfoByPetID(guid)
  A:Notify(("Summoned |T%s:16|t %s"):format(icon or 0, speciesName or "pet"))
end

-- Current zone mapID (Classic-safe)
local function CurrentMapID()
  if C_Map and C_Map.GetBestMapForUnit then
    return C_Map.GetBestMapForUnit("player")
  end
  -- MoP Classic ships with modern map API; fallback kept for safety.
  if GetCurrentMapAreaID then
    SetMapToCurrentZone()
    return GetCurrentMapAreaID()
  end
  return nil
end

local function DoSummon(fromAuto, forceLast)
  local okLoc, whyLoc = AllowedByLocation()
  if not okLoc then
    A:Notify(("Summon skipped (%s not allowed)."):format(whyLoc)); return
  end
  local okNow, whyNow = CanSummonNow()
  if not okNow then
    A:Notify(("Summon skipped (%s)."):format(whyNow)); return
  end

  local mode = S().randomMode or "ANY"
  local onlyFav = fromAuto and S().useFavoritesForAuto or false

  -- Prefer last on auto (or explicit force)
  if (forceLast or (fromAuto and APKDB.lastSummonedGUID)) and APKDB.lastSummonedGUID then
    local last = APKDB.lastSummonedGUID
    if not isBlk(last) and (not onlyFav or isFav(last))
        and (not C_PetJournal.PetIsSummonable or C_PetJournal.PetIsSummonable(last)) then
      SummonGUID(last)
      return
    end
  end

  local pool

  -- Zone set if enabled and present
  if S().zoneMode then
    local mapID = CurrentMapID()
    if mapID and S().zoneSets[mapID] and next(S().zoneSets[mapID]) ~= nil then
      pool = BuildPoolFromSet(S().zoneSets[mapID], onlyFav, mode)
    end
  end

  -- Fallbacks: favorites/collection
  if not pool or #pool == 0 then
    pool = BuildPoolFromCollection(onlyFav, mode)
    if #pool == 0 and onlyFav then
      A:Notify("No favorites matched filters. Falling back to any allowed pet.")
      pool = BuildPoolFromCollection(false, mode)
    end
  end

  local pick = RandPick(pool)
  if pick then SummonGUID(pick) else A:Notify("No eligible pets to summon.") end
end
A.DoSummon = DoSummon

-- Public for UI and macros
function A.ToggleFavorite(guid) if guid then APKDB.favorites[guid] = not APKDB.favorites[guid] or nil end end
function A.ToggleBlacklist(guid) if guid then APKDB.blacklist[guid] = not APKDB.blacklist[guid] or nil end end
function A.GetCount(guid) return APKDB.summonCount[guid] or 0 end
function A:Notify(msg) DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF99APK:|r " .. tostring(msg)) end

-- =========================
-- Events & slash (add Classic-friendly listeners)
-- =========================
local wasMounted = false
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
-- Keep UI lists fresh when collection changes in Pet Journal
f:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
-- Some Classic builds fire this after pet actions are ready
if UpdateSummonedPetAction or RegisterStateDriver then
  pcall(function() f:RegisterEvent("UPDATE_SUMMONPETS_ACTION") end)
end

f:SetScript("OnEvent", function(_, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    APKDB = copyDefaults(defaults, APKDB or {})
    if A.CreateSummonButton then A.CreateSummonButton() end
    if A.CreateMinimapButton then A.CreateMinimapButton() end
    print("|cFF00FF99APK loaded|r — /apk help")

  elseif event == "PLAYER_LOGIN" then
    C_Timer.After(2, function()
      wasMounted = IsMounted and IsMounted() or false
      if S().autoOnLogin then DoSummon(true) end
    end)

  elseif event == "PLAYER_ENTERING_WORLD" then
    wasMounted = IsMounted and IsMounted() or false

  elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
    local nowMounted = IsMounted and IsMounted() or false
    if wasMounted and not nowMounted then
      if S().autoOnDismount then C_Timer.After(0.4, function() DoSummon(true) end) end
    end
    wasMounted = nowMounted

  elseif event == "PET_JOURNAL_LIST_UPDATE" then
    if A.RefreshManager then A.RefreshManager() end
  end
end)

-- Slash commands
SLASH_APK1 = "/apk"
SLASH_APK2 = "/keeper"
SlashCmdList["APK"] = function(msg)
  msg = (msg or ""):lower()
  if msg == "" or msg == "summon" then
    DoSummon(false)
  elseif msg == "help" then
    A:Notify("Commands: /apk, /apk summon, /apk last, /apk options, /apk manager, /apk minimap show|hide|reset, /apk zone on|off|add|clear")
  elseif msg == "last" then
    DoSummon(false, true)
  elseif msg == "options" or msg == "opt" then
    if A.ShowOptions then A.ShowOptions() end
  elseif msg == "manager" or msg == "pets" then
    if A.ToggleManager then A.ToggleManager(true) end

  -- Minimap
  elseif msg == "minimap show" then
    S().minimap.show = true
    if A.MinimapButton then
      A.MinimapButton:Show()
    elseif A.CreateMinimapButton then
      A.CreateMinimapButton()
    end
    A:Notify("Minimap button shown.")
  elseif msg == "minimap hide" then
    S().minimap.show = false
    if A.MinimapButton then A.MinimapButton:Hide() end
    A:Notify("Minimap button hidden.")
  elseif msg == "minimap reset" then
    S().minimap.angle = 210
    S().minimap.radius = 115
    if A.CreateMinimapButton then A.CreateMinimapButton() end
    A:Notify("Minimap button reset.")

  -- Zone sets
  elseif msg == "zone on" then
    S().zoneMode = true; A:Notify("Zone mode ON.")
  elseif msg == "zone off" then
    S().zoneMode = false; A:Notify("Zone mode OFF.")
  elseif msg == "zone add" then
    local mapID = CurrentMapID()
    local guid = C_PetJournal.GetSummonedPetGUID and C_PetJournal.GetSummonedPetGUID()
    if not mapID or not guid then
      A:Notify("Need a map and a summoned pet to add."); return
    end
    S().zoneSets[mapID] = S().zoneSets[mapID] or {}
    S().zoneSets[mapID][guid] = true
    A:Notify("Added current pet to this zone's set.")
  elseif msg == "zone clear" then
    local mapID = CurrentMapID()
    if mapID and S().zoneSets[mapID] then
      S().zoneSets[mapID] = {}
      A:Notify("Cleared this zone's set.")
    else
      A:Notify("No set for this zone.")
    end
  else
    A:Notify("Unknown. Try /apk help")
  end
end

-- Safe stubs (UI may load later)
function A.CreateSummonButton() end
function A.CreateMinimapButton() end
