local A = APK
local function S() return APKDB.settings end

-- Helper: current summoned pet info
local function CurrentPet()
  local guid = C_PetJournal.GetSummonedPetGUID and C_PetJournal.GetSummonedPetGUID()
  if not guid then return nil end
  local _, _, _, _, _, _, _, name, icon = C_PetJournal.GetPetInfoByPetID(guid)
  return guid, name, icon
end

-- =========================
-- Main Summon Button (Blizz style)
-- =========================
function A.CreateSummonButton()
  if A.Button then return end
  local b = CreateFrame("Button", "APK_SummonButton", UIParent, "UIPanelButtonTemplate")
  b:SetSize(120, 24)
  b:SetText("Summon Pet")
  b:SetMovable(true)
  b:EnableMouse(true)
  b:RegisterForDrag("LeftButton")
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  b:SetScript("OnDragStart", function(self)
    if not S().buttonLocked then self:StartMoving() end
  end)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relTo, relPoint, x, y = self:GetPoint()
    S().buttonPoint = { point, relTo and relTo:GetName() or "UIParent", relPoint, x, y }
  end)

  b:SetScript("OnClick", function(_, btn)
    if btn == "RightButton" then
      if A.ShowOptions then A.ShowOptions() end
    else
      A.DoSummon(false)
    end
  end)

  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Azeroth Pet Keeper", 1, 1, 1)
    GameTooltip:AddLine("Left-click: Summon pet", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Right-click: Options", 0.9, 0.9, 0.9)
    local guid, name, icon = CurrentPet()
    GameTooltip:AddLine(" ")
    if guid then
      GameTooltip:AddLine(("Current: |T%s:16|t %s"):format(icon or 0, name or "Pet"), 0.8, 1, 0.8)
    else
      GameTooltip:AddLine("Current: none", 1, 0.6, 0.6)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local p = S().buttonPoint
  b:ClearAllPoints()
  b:SetPoint(p[1], _G[p[2]] or UIParent, p[3], p[4], p[5])

  A.Button = b
end

-- =========================
-- Minimap Button (no libs)
-- =========================
function A.CreateMinimapButton()
  if A.MinimapButton then
    if S().minimap and S().minimap.show then A.MinimapButton:Show() else A.MinimapButton:Hide() end
    return
  end

  local b = CreateFrame("Button", "APK_MinimapButton", Minimap)
  b:SetSize(32, 32)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(Minimap:GetFrameLevel() + 8)
  b:EnableMouse(true)
  b:RegisterForDrag("LeftButton")
  b:RegisterForClicks("AnyUp")

  -- Border + icon
  local overlay = b:CreateTexture(nil, "OVERLAY")
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetSize(54, 54)
  overlay:SetPoint("TOPLEFT")

  local icon = b:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Pet_PetTrap")
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER")

  -- Geometry helpers
  local function GetShape()
    return (type(GetMinimapShape) == "function" and GetMinimapShape()) or "ROUND"
  end
  local function GetAngle()
    local a = (S().minimap and S().minimap.angle) or 210
    return tonumber(a) or 210
  end
  local function SetAngle(a)
    S().minimap = S().minimap or {}
    if a < 0 then a = a + 360 end
    if a >= 360 then a = a - 360 end
    S().minimap.angle = a
  end
  -- push slightly *outside* the rim
  local function RimRadius()
    local r = math.min(Minimap:GetWidth(), Minimap:GetHeight()) / 2
    return r + 8
  end
  local function SetPosition()
    local angle = math.rad(GetAngle())
    local shape = GetShape()
    local r = RimRadius()
    local x = math.cos(angle) * r
    local y = math.sin(angle) * r

    if shape ~= "ROUND" then
      -- generic square clamp for square/corner shapes
      local lim = (math.min(Minimap:GetWidth(), Minimap:GetHeight()) / 2) * 0.7071
      x = math.max(-lim, math.min(lim, x))
      y = math.max(-lim, math.min(lim, y))
    end

    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", x, y)
  end
  local function UpdateAngleFromCursor()
    local scale = UIParent:GetEffectiveScale()
    local mx, my = Minimap:GetCenter()
    local px, py = GetCursorPosition()
    px, py = px / scale, py / scale
    local a = math.deg(math.atan2(py - my, px - mx))
    if a < 0 then a = a + 360 end
    SetAngle(a)
    SetPosition()
  end

  -- Behavior
  b:SetScript("OnDragStart", function(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", UpdateAngleFromCursor)
  end)
  b:SetScript("OnDragStop", function(self)
    self:UnlockHighlight()
    self:SetScript("OnUpdate", nil)
    SetPosition()
  end)
  b:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Azeroth Pet Keeper", 1, 1, 1)
    GameTooltip:AddLine("Left-click: Summon pet", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Right-click: Options", 0.9, 0.9, 0.9)
    GameTooltip:AddLine("Drag: Move around minimap", 0.9, 0.9, 0.9)
    local g = C_PetJournal.GetSummonedPetGUID and C_PetJournal.GetSummonedPetGUID()
    GameTooltip:AddLine(" ")
    if g then
      local _,_,_,_,_,_,_, name, ic = C_PetJournal.GetPetInfoByPetID(g)
      GameTooltip:AddLine(("Current: |T%s:16|t %s"):format(ic or 0, name or "Pet"), 0.8, 1, 0.8)
    else
      GameTooltip:AddLine("Current: none", 1, 0.6, 0.6)
    end
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnClick", function(_, btn)
    if btn == "RightButton" then
      if A.ShowOptions then A.ShowOptions() end
    else
      A.DoSummon(false)
    end
  end)

  Minimap:HookScript("OnSizeChanged", SetPosition)
  b:SetClampedToScreen(true)

  -- Init
  A.MinimapButton = b
  if not S().minimap then S().minimap = { show = true, angle = 210 } end
  if S().minimap.show then b:Show() else b:Hide() end
  SetPosition()
end

-- =========================
-- Options Panel
-- =========================
local options
function A.ShowOptions()
  if options and options:IsShown() then return end

  options = CreateFrame("Frame", "APK_Options", UIParent, "BasicFrameTemplateWithInset")
  options:SetSize(600, 520)
  options:SetPoint("CENTER")
  options:SetToplevel(true)
  options:SetClampedToScreen(true)
  options.TitleText:SetText("Azeroth Pet Keeper — Options")

  if options.CloseButton then
    options.CloseButton:ClearAllPoints()
    options.CloseButton:SetPoint("TOPRIGHT", options, "TOPRIGHT", -4, -4)
  end

  local scroll = CreateFrame("ScrollFrame", "APK_OptionsScroll", options, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 12, -36)
  scroll:SetPoint("BOTTOMRIGHT", -30, 14)

  local scrollContent = CreateFrame("Frame", nil, scroll)
  scrollContent:SetSize(1, 1)
  scroll:SetScrollChild(scrollContent)

  local y = -10
  local function addCheck(text, key, tip)
    local cb = CreateFrame("CheckButton", nil, scrollContent, "UICheckButtonTemplate")
    cb:SetSize(20, 20) -- Classic-safe explicit size
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.text:SetText(text)
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetChecked(S()[key])
    cb:SetScript("OnClick", function(self) S()[key] = self:GetChecked() and true or false end)
    if tip then cb.tooltipText = tip end
    y = y - 28
    return cb
  end

  -- Core toggles
  addCheck("Auto-summon at Login", "autoOnLogin", "Summon a pet shortly after login.")
  addCheck("Auto-summon after Dismount", "autoOnDismount", "Summon when you dismount.")
  addCheck("Allow Indoors", "allowIndoors", "Permit summoning indoors.")
  addCheck("Allow Outdoors", "allowOutdoors", "Permit summoning outdoors.")
  addCheck("Allow in Raids", "allowInRaid", "Permit summoning while in a raid.")
  addCheck("Use Favorites for Auto-summon", "useFavoritesForAuto", "Auto uses only Favorites (if any).")
  addCheck("Lock Summon Button", "buttonLocked", "Prevent dragging the on-screen button.")

  -- Random mode dropdown (keep for compatibility; functional in MoP)
  local function ModeLabel(v)
    if v == "FLYING" then
      return "Flying"
    elseif v == "NONFLYING" then
      return "Non-Flying"
    else
      return "Any"
    end
  end
  if S().randomMode ~= "ANY" and S().randomMode ~= "FLYING" and S().randomMode ~= "NONFLYING" then
    S().randomMode = "ANY"
  end

  local ddLabel = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  ddLabel:SetPoint("TOPLEFT", 16, y - 6)
  ddLabel:SetText("Random Mode")

  local dd = CreateFrame("Frame", "APK_ModeDropdown", scrollContent, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", ddLabel, "BOTTOMLEFT", -18, -4)

  UIDropDownMenu_Initialize(dd, function(self, level)
    local function add(val, txt)
      local info = UIDropDownMenu_CreateInfo()
      info.text = txt
      info.func = function()
        S().randomMode = val
        UIDropDownMenu_SetSelectedValue(dd, val)
        UIDropDownMenu_SetText(dd, ModeLabel(val))
      end
      info.checked = (S().randomMode == val)
      UIDropDownMenu_AddButton(info, level)
    end
    add("ANY", "Any")
    add("FLYING", "Flying")
    add("NONFLYING", "Non-Flying")
  end)
  UIDropDownMenu_SetWidth(dd, 160)
  UIDropDownMenu_SetSelectedValue(dd, S().randomMode)
  UIDropDownMenu_SetText(dd, ModeLabel(S().randomMode))
  y = y - 70

  -- Minimap toggle
  do
    local cb = CreateFrame("CheckButton", nil, scrollContent, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.text:SetText("Show Minimap Button")
    cb:SetPoint("TOPLEFT", 16, y)
    cb:SetChecked(S().minimap and S().minimap.show)
    cb.tooltipText = "Toggle the APK minimap button (left-click: summon, right-click: options)."
    cb:SetScript("OnClick", function(self)
      local show = self:GetChecked() and true or false
      S().minimap = S().minimap or {}; S().minimap.show = show
      if show then
        if A.MinimapButton then
          A.MinimapButton:Show()
        elseif type(A.CreateMinimapButton) == "function" then
          A.CreateMinimapButton()
        end
      else
        if A.MinimapButton then A.MinimapButton:Hide() end
      end
    end)
    y = y - 28
  end

  -- Zone-based pets (with descriptive tip)
  do
    local cb = addCheck("Enable Zone-based Pets", "zoneMode")
    y = y + 28
    local tip = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    tip:SetText("Use /apk zone add to add your current pet to this zone; /apk zone clear to clear it.")
    tip:SetPoint("TOPLEFT", cb.text, "BOTTOMLEFT", 0, -2)
    y = y - 28 - 24
  end

  -- Bottom buttons
  local summonNow = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
  summonNow:SetSize(110, 22)
  summonNow:SetPoint("BOTTOMRIGHT", -36, 12)
  summonNow:SetText("Summon Now")
  summonNow:SetScript("OnClick", function() A.DoSummon(false) end)

  local openMgr = CreateFrame("Button", nil, options, "UIPanelButtonTemplate")
  openMgr:SetSize(110, 22)
  openMgr:SetPoint("RIGHT", summonNow, "LEFT", -6, 0)
  openMgr:SetText("Pet Manager")
  openMgr:SetScript("OnClick", function()
    A.ToggleManager(true)
    if APK_Manager then
      APK_Manager:SetFrameStrata("DIALOG")
      APK_Manager:SetFrameLevel(options:GetFrameLevel() + 50)
      APK_Manager:Raise()
    end
  end)

  scrollContent:SetHeight(-y + 20)
end

-- =========================
-- Pet Manager (favorites/blacklist/counters)
-- =========================
local manager, rows

-- expose a refresh helper (called on PET_JOURNAL_LIST_UPDATE)
function A.RefreshManager()
  if not manager or not manager:IsShown() then return end
  if manager._build then manager:_build() end
end

function A.ToggleManager(show)
  if manager and manager:IsShown() and not show then
    manager:Hide()
    return
  end

  if not manager then
    manager = CreateFrame("Frame", "APK_Manager", UIParent, "BasicFrameTemplateWithInset")
    manager:SetSize(540, 480)
    manager:SetPoint("CENTER")
    manager:SetToplevel(true)
    manager:SetFrameStrata("DIALOG")
    manager:SetFrameLevel((APK_Options and APK_Options:GetFrameLevel() or 100) + 50)
    manager:Raise()
    manager.TitleText:SetText("Azeroth Pet Keeper — Pet Manager")

    if manager.CloseButton then
      manager.CloseButton:ClearAllPoints()
      manager.CloseButton:SetPoint("TOPRIGHT", manager, "TOPRIGHT", -4, -4)
    end

    -- Headers
    local h1 = manager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h1:SetPoint("TOPLEFT", 16, -36); h1:SetText("Name")

    local h4 = manager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h4:SetPoint("TOPRIGHT", -36, -36); h4:SetText("Count")

    local h3 = manager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h3:SetPoint("RIGHT", h4, "LEFT", -28, 0); h3:SetText("Blacklist")

    local h2 = manager:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- shift header slightly left so the Favorite checkbox column aligns visually
    h2:SetPoint("RIGHT", h3, "LEFT", -36, 0); h2:SetText("Favorite")

    local scroll = CreateFrame("ScrollFrame", "APK_ManagerScroll", manager, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 12, -56)
    scroll:SetPoint("BOTTOMRIGHT", -30, 44)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    content:SetPoint("TOPRIGHT", scroll, "TOPRIGHT", 0, 0)
    content:SetHeight(1)
    scroll:SetScrollChild(content)

    rows = {}
    local ROW_H = 24

    local function build()
      -- sync width (minus scrollbar gutter)
      local w = scroll:GetWidth() - 20
      if w > 0 then content:SetWidth(w) end

      for _, r in ipairs(rows) do r:Hide() end
      wipe(rows)

      local n = C_PetJournal.GetNumPets()
      local y = -2
      for i = 1, n do
        local guid, _, owned, customName, _, _, _, speciesName, icon = C_PetJournal.GetPetInfoByIndex(i)
        if owned and guid then
          local row = CreateFrame("Frame", nil, content)
          row:SetHeight(ROW_H)
          row:SetPoint("TOPLEFT", 4, y)
          row:SetPoint("RIGHT", content, "RIGHT", -8, 0)

          local iconTex = row:CreateTexture(nil, "ARTWORK")
          iconTex:SetSize(18, 18); iconTex:SetPoint("LEFT", 2, 0); iconTex:SetTexture(icon)

          local cnt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
          cnt:SetPoint("RIGHT", row, "RIGHT", -8, 0)

          local blk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
          blk:SetSize(20, 20)
          blk:SetPoint("RIGHT", cnt, "LEFT", -22, 0)

          local fav = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
          fav:SetSize(20, 20)
          fav:SetPoint("RIGHT", blk, "LEFT", -36, 0) -- moved left to align under header

          local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
          name:SetPoint("LEFT", iconTex, "RIGHT", 6, 0)
          name:SetPoint("RIGHT", fav, "LEFT", -10, 0)
          name:SetJustifyH("LEFT")
          name:SetText((customName and (customName .. " |cff808080(" .. speciesName .. ")|r")) or speciesName)

          fav:SetChecked(APKDB.favorites[guid] or false)
          fav:SetScript("OnClick", function() A.ToggleFavorite(guid) end)

          blk:SetChecked(APKDB.blacklist[guid] or false)
          blk:SetScript("OnClick", function() A.ToggleBlacklist(guid) end)

          cnt:SetText(APKDB.summonCount[guid] or 0)

          rows[#rows + 1] = row
          y = y - ROW_H
        end
      end
      content:SetHeight(#rows * ROW_H + 8)
    end

    manager._build = build

    local refresh = CreateFrame("Button", nil, manager, "UIPanelButtonTemplate")
    refresh:SetSize(90, 22)
    refresh:SetPoint("BOTTOMLEFT", 12, 12)
    refresh:SetText("Refresh")
    refresh:SetScript("OnClick", build)

    scroll:SetScript("OnSizeChanged", function() build() end)
    build()
  end

  if show then
    manager:Show()
    manager:SetFrameStrata("DIALOG")
    manager:SetFrameLevel((APK_Options and APK_Options:GetFrameLevel() or manager:GetFrameLevel()) + 50)
    manager:Raise()
  else
    manager:Hide()
  end
end
