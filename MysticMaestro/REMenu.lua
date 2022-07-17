local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local MYSTIC_ENCHANTS = MYSTIC_ENCHANTS

local AwAddonsTexturePath = "Interface\\AddOns\\AwAddons\\Textures\\"

local queryResults = {}
do -- Create RE search box widget "EditBoxMysticMaestroREPredictor"
  LibStub("AceGUI-3.0-Search-EditBox"):Register(
    "MysticMaestroREPredictor",
    {
      GetValues = function(self, text, _, max)
        wipe(queryResults)
        text = text:lower()
        for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
          if enchantID ~= 0 then
            local enchantName = MM.RE_NAMES[enchantID]
            if enchantName and enchantName:lower():find(text) then
              queryResults[enchantID] = MM:cTxt(enchantName, tostring(enchantData.quality))
              max = max - 1
              if max == 0 then
                return queryResults
              end
            end
          end
        end
        return queryResults
      end,
      GetValue = function(self, text, key)
        local enchantName
        if key then
          enchantName = queryResults[key]:match("|c........(.-)|r")
          MM:SetResultSet({key})
          MM:GoToPage(1)
          MM:SetSelectedEnchantButton(1)
          return key, enchantName
        else
          key, enchantName = next(queryResults)
          if key then
            enchantName = enchantName:match("|c........(.-)|r")
            MM:SetResultSet({key})
            MM:GoToPage(1)
            MM:SetSelectedEnchantButton(1)
            return key, enchantName
          end
        end
      end,
      GetHyperlink = function(self, key)
        return "spell:" .. MYSTIC_ENCHANTS[key].spellID
      end
    }
  )

  -- IDK what this does, but it is required
  local myOptions = {
    type = "group",
    args = {
      editbox1 = {
        type = "input",
        dialogControl = "EditBoxMysticMaestroREPredictor",
        name = "Type a spell name",
        get = function()
        end,
        set = function(_, v)
          print(v)
        end
      }
    }
  }

  LibStub("AceConfig-3.0"):RegisterOptionsTable("MysticMaestro", myOptions)
end

local numEnchantButtons = 8
local enchantButtons = {}
local prevPageButton, nextPageButton, pageTextFrame
local enchantContainer, statsContainer, graphContainer, currencyContainer
local initializeStandaloneMenuContainer, initializeMenu
do -- functions to initialize menu and menu container
  local FrameBackdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 8, right = 8, top = 8, bottom = 8}
  }

  local EdgelessFrameBackdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 8, right = 8, top = 8, bottom = 8}
  }

  function initializeStandaloneMenuContainer()
    local standaloneMenuContainer = CreateFrame("Frame", "MysticMaestroMenuContainer", UIParent)
    table.insert(UISpecialFrames, standaloneMenuContainer:GetName())
    standaloneMenuContainer:Hide()
    standaloneMenuContainer:EnableMouse(true)
    standaloneMenuContainer:SetMovable(true)
    standaloneMenuContainer:SetResizable(false)
    standaloneMenuContainer:SetFrameStrata("DIALOG")
    standaloneMenuContainer:SetBackdrop(FrameBackdrop)
    standaloneMenuContainer:SetBackdropColor(0, 0, 0, 1)
    standaloneMenuContainer:SetToplevel(true)
    standaloneMenuContainer:SetPoint("CENTER")
    standaloneMenuContainer:SetSize(635, 412)
    standaloneMenuContainer:SetClampedToScreen(true)
    standaloneMenuContainer:SetScript("OnHide", function(self) MM:HideMysticMaestroMenu() end)

    -- function from WeakAuras Options for pretty border
    local function CreateDecoration(frame, width)
      local deco = CreateFrame("Frame", nil, frame)
      deco:SetSize(width, 40)

      local bg1 = deco:CreateTexture(nil, "DIALOG")
      bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
      bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
      bg1:SetAllPoints(deco)

      local bg2 = deco:CreateTexture(nil, "DIALOG")
      bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
      bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
      bg2:SetPoint("RIGHT", bg1, "LEFT", 1, 0)
      bg2:SetSize(10, 40)

      local bg3 = deco:CreateTexture(nil, "DIALOG")
      bg3:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
      bg3:SetTexCoord(0.72, 0.76, 0, 0.63)
      bg3:SetPoint("LEFT", bg1, "RIGHT", -1, 0)
      bg3:SetSize(10, 40)

      return deco
    end

    local title = CreateDecoration(standaloneMenuContainer, 130)
    title:SetPoint("TOP", 0, 24)
    title:EnableMouse(true)
    title:SetScript(
      "OnMouseDown",
      function(f)
        f:GetParent():StartMoving()
      end
    )
    title:SetScript(
      "OnMouseUp",
      function(f)
        f:GetParent():StopMovingOrSizing()
      end
    )

    local titletext = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titletext:SetPoint("CENTER", title)
    titletext:SetText("Mystic Maestro")

    local close = CreateDecoration(standaloneMenuContainer, 17)
    close:SetPoint("TOPRIGHT", -30, 12)

    local closebutton = CreateFrame("BUTTON", nil, close, "UIPanelCloseButton")
    closebutton:SetPoint("CENTER", close, "CENTER", 1, -1)
    closebutton:SetScript(
      "OnClick",
      function()
        HideUIPanel(MysticMaestroMenuContainer)
      end
    )
  end

  local mmf
  local function createMenu()
    mmf = CreateFrame("Frame", "MysticMaestroMenu", UIParent)
    mmf:Hide()
    mmf:SetSize(609, 378)
  end

  local function createContainer(parent, anchorPoint, width, height, xOffset, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetResizable(false)
    container:SetBackdrop(EdgelessFrameBackdrop)
    container:SetBackdropColor(0, 0, 0, 1)
    container:SetToplevel(true)
    container:SetPoint(anchorPoint, parent, anchorPoint, xOffset or 0, yOffset or 0)
    container:SetSize(width, height)
    return container
  end

  local function getOrbCurrency()
    return GetItemCount(98570)
  end

  local function getExtractCurrency()
    return GetItemCount(98463)
  end

  local enchantContainerHeight = 12
  local function updateCurrencyDisplay()
    currencyContainer.FontString:SetFormattedText("%s: |cFFFFFFFF%d|r %s %s: |cFFFFFFFF%d|r %s",
    "Orbs", getOrbCurrency(), CreateTextureMarkup("Interface\\Icons\\inv_custom_CollectionRCurrency", 64, 64, enchantContainerHeight, enchantContainerHeight, 0, 1, 0, 1),
    "Extracts", getExtractCurrency(), CreateTextureMarkup("Interface\\Icons\\Inv_Custom_MysticExtract", 64, 64, enchantContainerHeight, enchantContainerHeight, 0, 1, 0, 1))
  end

  local function createCurrencyContainer(parent)
    local width = parent:GetWidth()
    currencyContainer = CreateFrame("Frame", nil, parent)
    currencyContainer:SetSize(width, enchantContainerHeight)
    currencyContainer:SetPoint("BOTTOM", parent, "BOTTOM", 0, 11)
    currencyContainer.FontString = currencyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    currencyContainer.FontString:SetPoint("CENTER", currencyContainer, "CENTER")
    currencyContainer.FontString:SetSize(currencyContainer:GetWidth(), currencyContainer:GetHeight())
    updateCurrencyDisplay()
  end

  local function setUpCurrencyDisplay(enchantContainer)
    createCurrencyContainer(enchantContainer)
    MM:RegisterBucketEvent({"BAG_UPDATE"}, .2, updateCurrencyDisplay)
  end

  local function createEnchantButton(enchantContainer, i)
    local enchantButton = CreateFrame("Button", nil, enchantContainer)
    enchantButton:SetSize(enchantContainer:GetWidth() - 16, 36)
    enchantButton:SetPoint("TOP", enchantContainer, "TOP", 0, -(i-1)*36-8)
    enchantButton:SetScript("OnLeave",
    function(self)
      GameTooltip:Hide()
      if self ~= MM:GetSelectedEnchantButton() then
        self.H:Hide()
      end
    end)
    enchantButton:SetScript("OnClick", function(self)
      local filterDropdown = MM:GetFilterDropdown()
      if filterDropdown.open then
        filterDropdown.pullout:Close()
      end
      MM:SetSelectedEnchantButton(self) 
    end)
    enchantButton:Hide()

    enchantButton.BG = enchantButton:CreateTexture(nil, "DIALOG")
    enchantButton.BG:SetTexture(AwAddonsTexturePath .. "CAOverhaul\\SpellSlot")
    enchantButton.BG:SetSize(248, 66)
    enchantButton.BG:SetPoint("CENTER", 19, 0)

    enchantButton.H = enchantButton:CreateTexture(nil, "OVERLAY")
    enchantButton.H:SetTexture(AwAddonsTexturePath .. "CAOverhaul\\SpellSlot_Highlight")
    enchantButton.H:SetSize(248, 59)
    enchantButton.H:SetPoint("CENTER", 19, 0)
    enchantButton.H:SetBlendMode("ADD")
    enchantButton.H:SetDesaturated()
    enchantButton.H:Hide()

    enchantButton.Icon = enchantButton:CreateTexture(nil, "DIALOG")
    enchantButton.Icon:SetTexture("Interface\\Icons\\5_dragonfirebreath")
    enchantButton.Icon:SetSize(32, 32)
    enchantButton.Icon:SetPoint("CENTER", -74, 0)

    enchantButton.IconBorder = enchantButton:CreateTexture(nil, "OVERLAY")
    enchantButton.IconBorder:SetTexture(AwAddonsTexturePath .. "LootTex\\Loot_Icon_Purple")
    enchantButton.IconBorder:SetSize(38, 38)
    enchantButton.IconBorder:SetPoint("CENTER", -74, 0)

    enchantButton.REText = enchantButton:CreateFontString()
    enchantButton.REText:SetFontObject(GameFontNormal)
    enchantButton.REText:SetPoint("CENTER", 19, 0)
    enchantButton.REText:SetText("|cff00ff00Blade Vortex|r")
    enchantButton.REText:SetJustifyH("CENTER")
    enchantButton.REText:SetSize(148, 36)

    return enchantButton
  end

  local function createEnchantButtons(enchantContainer)
    for i=1, numEnchantButtons do
      table.insert(enchantButtons, createEnchantButton(enchantContainer, i))
    end
  end

  local paginationVerticalPosition = 22
  local function createPageButton(enchantContainer, prevOrNext, xOffset, yOffset)
    local pageButton = CreateFrame("BUTTON", nil, enchantContainer)
    pageButton:SetSize(32, 32)
    pageButton:SetPoint("BOTTOM", enchantContainer, "BOTTOM", xOffset, yOffset)
    pageButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Up")
    pageButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Down")
    pageButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. prevOrNext .."Page-Disabled")
    pageButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    pageButton:SetScript("OnClick", function(self)
      MM[prevOrNext.."Page"](MM)
    end)
    return pageButton
  end

  local function createPageTextFrame(enchantContainer, xOffset, yOffset)
    pageTextFrame = CreateFrame("FRAME", nil, enchantContainer)
    pageTextFrame:SetSize(60, 32)
    pageTextFrame:SetPoint("BOTTOM", enchantContainer, "BOTTOM", xOffset, yOffset)
    pageTextFrame.Text = pageTextFrame:CreateFontString()
    pageTextFrame.Text:SetFontObject(GameFontNormal)
    pageTextFrame.Text:SetAllPoints()
    pageTextFrame.Text:SetJustifyH("CENTER")
  end

  local function createPagination(enchantContainer)
    prevPageButton = createPageButton(enchantContainer, "Prev", -42, paginationVerticalPosition)
    nextPageButton = createPageButton(enchantContainer, "Next", 42, paginationVerticalPosition)
    createPageTextFrame(enchantContainer, 0, paginationVerticalPosition)
  end

  local refreshButton
  local function createRefreshButton(mmf)
    refreshButton = CreateFrame("BUTTON", nil, mmf)
    refreshButton:SetSize(18, 18)
    refreshButton:SetPoint("CENTER", mmf, "TOPLEFT", 186, -14)
    refreshButton:SetNormalTexture("Interface\\BUTTONS\\UI-RefreshButton")
    refreshButton:SetScript("OnClick",
    function(self)
      MM:SetSearchBarDefaultText()
      MM:FilterMysticEnchants()
      MM:GoToPage(1)
    end)
  end

  function initializeMenu()
    createMenu()
    enchantContainer = createContainer(mmf, "BOTTOMLEFT", 200, 350)
    enchantContainer:EnableMouseWheel()
    enchantContainer:SetScript("OnMouseWheel",
    function(self, delta)
      if delta == 1 then
        MM:PrevPage()
      else
        MM:NextPage()
      end
    end)
    statsContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 150)
    graphContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 186, 0, 163)
    MM:InitializeGraph("MysticEnchantStatsGraph", graphContainer, "BOTTOMLEFT", "BOTTOMLEFT", 8, 9, 396, 170)
    setUpCurrencyDisplay(enchantContainer)
    createEnchantButtons(enchantContainer)
    createPagination(enchantContainer)
    createRefreshButton(mmf)
  end
end

do -- hook and display MysticMaestroMenu in AuctionFrame
  local function initAHTab()
    MM.AHTabIndex = AuctionFrame.numTabs+1
    local framename = "AuctionFrameTab"..MM.AHTabIndex
    local frame = CreateFrame("Button", framename, AuctionFrame, "AuctionTabTemplate")
    frame:SetID(MM.AHTabIndex);
    frame:SetText("Mystic Maestro");
    frame:SetPoint("LEFT", _G["AuctionFrameTab"..MM.AHTabIndex-1], "RIGHT", -8, 0);

    PanelTemplates_SetNumTabs (AuctionFrame, MM.AHTabIndex);
    PanelTemplates_EnableTab  (AuctionFrame, MM.AHTabIndex);
    return frame
  end

  local function MMTab_OnClick(self, index)
    if not MysticMaestroMenu then
      initializeMenu()
    end
    local index = self:GetID()
    if index ~= MM.AHTabIndex then
      AuctionPortraitTexture:Show()
      if MysticMaestroMenu:GetParent() == AuctionFrame and MysticMaestroMenu:IsVisible() then
        MM:HideMysticMaestroMenu()
      end
    else
      AuctionPortraitTexture:Hide()
      AuctionFrameTopLeft:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\UI-AuctionFrame-MysticMaestro-TopLeft");
      AuctionFrameTop:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top");
      AuctionFrameTopRight:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight");
      AuctionFrameBotLeft:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft");
      AuctionFrameBot:SetTexture("Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot");
      AuctionFrameBotRight:SetTexture("Interface\\AddOns\\MysticMaestro\\textures\\UI-AuctionFrame-MysticMaestro-BotRight");
      MysticMaestroMenu:ClearAllPoints()
      MysticMaestroMenu:SetPoint("BOTTOMLEFT", AuctionFrame, "BOTTOMLEFT", 13, 31)
      MysticMaestroMenu:SetParent(AuctionFrame)
      if MysticMaestroMenuContainer and MysticMaestroMenuContainer:IsVisible() then
        MysticMaestroMenuContainer:Hide()
      end
      MM:ShowMysticMaestroMenu()
    end
  end

  local mm_orig_AuctionFrameTab_OnClick
  function MM:REMenu_ADDON_LOADED(event, addonName)
    if addonName ~= "Blizzard_AuctionUI" then return end
    local tab = initAHTab()
    mm_orig_AuctionFrameTab_OnClick = AuctionFrameTab_OnClick
    AuctionFrameTab_OnClick = function(self, index, down)
      mm_orig_AuctionFrameTab_OnClick(self, index, down)
      MMTab_OnClick(self, index, down)
    end
    self:HookScript(AuctionFrame, "OnHide",
    function()
      if MysticMaestroMenu and MysticMaestroMenu:IsShown() and MysticMaestroMenu:GetParent() == AuctionFrame then
        self:HideMysticMaestroMenu()
      end
    end)
  end

  MM:RegisterEvent("ADDON_LOADED", "REMenu_ADDON_LOADED")
end

do  -- display MysticMaestroMenu in standalone container
  function MM:OpenStandaloneMenu()
    if not MysticMaestroMenuContainer then
      initializeStandaloneMenuContainer()
    end
    if not MysticMaestroMenu then
      initializeMenu()
    end
    MysticMaestroMenu:ClearAllPoints()
    MysticMaestroMenu:SetPoint("BOTTOMLEFT", MysticMaestroMenuContainer, "BOTTOMLEFT", 13, 9)
    MysticMaestroMenu:SetParent(MysticMaestroMenuContainer)
    self:ShowMysticMaestroMenu()
    MysticMaestroMenuContainer:Show()
  end
end

local currentFilter, currentSort
local statsContainerWidgets = {}
do -- show and hide MysticMaestroMenu
  local filterOptions = {
    "All Qualities",
    "Uncommon", 
    "Rare",
    "Epic",
    "Legendary",
    "-------------",
    "Known & Unknown",
    "Known",
    "Unknown",
    "-------------",
    "Favorites",
    "-------------"
  }

  local function itemsToFilter(items)
    currentFilter = {
      allQualities = items[1]:GetValue(),
      uncommon = items[2]:GetValue(),
      rare = items[3]:GetValue(),
      epic = items[4]:GetValue(),
      legendary = items[5]:GetValue(),
      allKnown = items[7]:GetValue(),
      known = items[8]:GetValue(),
      unknown = items[9]:GetValue(),
      favorites = items[11]:GetValue()
    }
    return currentFilter
  end

  local function filterToItems(filterDropdown, filter)
    filterDropdown:SetItemValue(1, filter.allQualities)
    filterDropdown:SetItemValue(2, filter.uncommon)
    filterDropdown:SetItemValue(3, filter.rare)
    filterDropdown:SetItemValue(4, filter.epic)
    filterDropdown:SetItemValue(5, filter.legendary)
    filterDropdown:SetItemValue(7, filter.allKnown)
    filterDropdown:SetItemValue(8, filter.known)
    filterDropdown:SetItemValue(9, filter.unknown)
    filterDropdown:SetItemValue(11, filter.favorites)
  end

  local function filterDropdown_OnValueChanged(self, event, key, checked)
    local items = self.pullout.items
    if key == 1 then
      if checked then
        items[2]:SetValue(nil)
        items[3]:SetValue(nil)
        items[4]:SetValue(nil)
        items[5]:SetValue(nil)
      else
        items[1]:SetValue(true)
      end
    elseif key == 2 or key == 3 or key == 4 or key == 5 then
      if checked then
        if items[2]:GetValue() and items[3]:GetValue() and items[4]:GetValue() and items[5]:GetValue() then
          items[2]:SetValue(nil)
          items[3]:SetValue(nil)
          items[4]:SetValue(nil)
          items[5]:SetValue(nil)
          items[1]:SetValue(true)
        else
          items[1]:SetValue(nil)
        end
      else
        if not (items[2]:GetValue() or items[3]:GetValue() or items[4]:GetValue() or items[5]:GetValue()) then
          items[1]:SetValue(true)
        end
      end
    elseif key == 7 or key == 8 or key == 9 then
      items[7]:SetValue(key == 7 or nil)
      items[8]:SetValue(key == 8 or nil)
      items[9]:SetValue(key == 9 or nil)
    end
    if items[key]:GetValue() == checked or key > 1 and key < 6 and items[1]:GetValue() then
      MM:SetSearchBarDefaultText()
      MM:FilterMysticEnchants(itemsToFilter(items))
      MM:GoToPage(1)
    end
  end

  local sortOptions = {
    "Alphabetical (Ascending)",
    "Alphabetical (Descending)",
    "Gold/Orb (Min)",
    "Gold/Orb (Med)",
    "Gold/Orb (Mean)",
    "Gold/Orb (Max)",
    "Gold/Orb (10d_Min)",
    "Gold/Orb (10d_Med)",
    "Gold/Orb (10d_Mean)",
    "Gold/Orb (10d_Max)"
  }

  local function sortDropdown_OnValueChanged(self, event, key, checked)
    local items = self.pullout.items
    items[1]:SetValue(key == 1 or nil)
    items[2]:SetValue(key == 2 or nil)
    MM:SetSearchBarDefaultText()
    currentSort = key
    MM:SortMysticEnchants(key)
    MM:GoToPage(1)
  end

  local sortDropdown, filterDropdown

  function MM:GetFilterDropdown()
    return filterDropdown
  end

  local function setUpDropdownWidgets()
    filterDropdown = AceGUI:Create("Dropdown")
    filterDropdown.frame:SetParent(MysticMaestroMenu)
    filterDropdown:SetPoint("TOPRIGHT", MysticMaestroMenu, "TOPRIGHT", -6, 0)
    filterDropdown:SetWidth(160)
    filterDropdown:SetHeight(27)
    filterDropdown:SetMultiselect(true)
    filterDropdown:SetList(filterOptions)
    filterDropdown:SetItemDisabled(6, true)
    filterDropdown:SetItemDisabled(10, true)
    filterDropdown:SetItemDisabled(12, true)
    if not currentFilter then
      filterDropdown:SetItemValue(1, true)
      filterDropdown:SetItemValue(7, true)
    else
      filterToItems(filterDropdown, currentFilter)
    end
    filterDropdown:SetCallback("OnValueChanged", filterDropdown_OnValueChanged)
    filterDropdown.frame:Show()

    sortDropdown = AceGUI:Create("Dropdown")
    sortDropdown.frame:SetParent(MysticMaestroMenu)
    sortDropdown:SetPoint("TOPLEFT", MysticMaestroMenu, "TOPLEFT", 8, 0)
    sortDropdown:SetWidth(160)
    sortDropdown:SetHeight(27)
    sortDropdown:SetList(sortOptions)
    sortDropdown:SetValue(currentSort or 1)
    sortDropdown:SetCallback("OnValueChanged", sortDropdown_OnValueChanged)
    sortDropdown.frame:Show()
  end

  local defaultSearchText = "|cFF777777Search|r"

  local searchBar

  function MM:SetSearchBarDefaultText()
    searchBar:SetText(defaultSearchText)
    searchBar.editBox:ClearFocus()
  end

  local function setUpSearchWidget()
    searchBar = AceGUI:Create("EditBoxMysticMaestroREPredictor")
    searchBar.frame:SetParent(MysticMaestroMenu)
    searchBar:SetPoint("TOP", MysticMaestroMenu, "TOP")
    searchBar:SetWidth(200)
    searchBar:SetText(defaultSearchText)
    searchBar.editBox:ClearFocus()
    searchBar:SetCallback(
      "OnEnterPressed",
      function(self, event, enchantID)
        self.editBox:ClearFocus()
      end
    )
    searchBar.editBox:HookScript(
      "OnEditFocusGained",
      function(self)
        if searchBar.lastText == defaultSearchText then
          searchBar:SetText("")
        end
      end
    )
    searchBar.editBox:HookScript(
      "OnEditFocusLost",
      function(self)
        if searchBar.lastText == "" then
          searchBar:SetText(defaultSearchText)
        end
      end
    )
    searchBar.frame:Show()
  end

  local function setUpStatisticsWidgets()
    for i=1, 12 do
      local label = AceGUI:Create("Label")
      label.frame:SetParent(statsContainer)
      label:SetWidth(182)
      label:SetHeight(18)
      label:SetPoint("TOPLEFT", statsContainer, "CENTER", i < 7 and -182 or 16, 72-18*((i - 1) % 6 + 1))
      label:SetFontObject(GameFontNormal)
      label.frame:Show()
      table.insert(statsContainerWidgets, label)
    end
  end

  function MM:ShowMysticMaestroMenu()
    setUpDropdownWidgets()
    setUpSearchWidget()
    setUpStatisticsWidgets()
    self:ClearGraph()
    self:FilterMysticEnchants(currentFilter or {allQualities = true, allKnown = true})
    self:GoToPage(1)
    MysticMaestroMenu:Show()
  end

  local function tearDownWidgets()
    sortDropdown:Release()
    filterDropdown:Release()
    searchBar:Release()
    for i=1, #statsContainerWidgets do
      statsContainerWidgets[i]:Release()
    end
    wipe(statsContainerWidgets)
  end

  function MM:HideMysticMaestroMenu()
    tearDownWidgets()
    MM:HideEnchantButtons()
    wipe(queryResults)
    MysticMaestroMenu:Hide()
  end

  function MM:HandleMenuSlashCommand()
    if MysticMaestroMenu and MysticMaestroMenu:IsVisible()
    and MysticMaestroMenu:GetParent() == MysticMaestroMenuContainer then
      HideUIPanel(MysticMaestroMenuContainer)
    else
      if AuctionFrame and AuctionFrame:IsVisible() and AuctionFrame.selectedTab == self.AHTabIndex then
        self:HideMysticMaestroMenu()
        HideUIPanel(AuctionFrame)
      end
      self:OpenStandaloneMenu()
    end
  end
end

local resultSet
do -- filter functions
  function MM:SetResultSet(set)
    resultSet = set
  end

  function MM:GetResultSet()
    return resultSet
  end

  local function qualityCheckMet(enchantID, filter)
    local quality = MYSTIC_ENCHANTS[enchantID].quality
    return filter.allQualities
    or filter.uncommon and quality == 2
    or filter.rare and quality == 3
    or filter.epic and quality == 4
    or filter.legendary and quality == 5
  end

  local function knownCheckMet(enchantID, filter)
    local known = IsReforgeEnchantmentKnown(enchantID)
    return filter.allKnown
    or filter.known and known
    or filter.unknown and not known
  end

  local function favoriteCheckMet(enchantID, filter)
    return not filter.favorites or MM.db.realm.FAVORITE_ENCHANTS[enchantID]
  end

  function MM:FilterMysticEnchants(filter)
    filter = filter or currentFilter
    currentFilter = filter
    resultSet = {}
    for enchantID, enchantData in pairs(MYSTIC_ENCHANTS) do
      if enchantID ~= 0 and qualityCheckMet(enchantID, filter)
      and knownCheckMet(enchantID, filter) and favoriteCheckMet(enchantID, filter) then
        table.insert(resultSet, enchantID)
      end
    end
    self:SortMysticEnchants(currentSort or 1)
  end
end

do -- sort functions
  local itemKeyToSortFunctionKey = {
    "alphabetical_asc",
    "alphabetical_des",
    "goldperorb_min",
    "goldperorb_med",
    "goldperorb_mean",
    "goldperorb_max",
    "goldperorb_10d_min",
    "goldperorb_10d_med",
    "goldperorb_10d_mean",
    "goldperorb_10d_max",
  }

  local sortFunctions = {
    alphabetical_asc = function(k1, k2) return MM:Compare(MM.RE_NAMES[k1],MM.RE_NAMES[k2],"<") end,
    alphabetical_des = function(k1, k2) return MM:Compare(MM.RE_NAMES[k1],MM.RE_NAMES[k2],">") end,
    goldperorb_min = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Min"), MM:OrbValue(k2,"Min"), ">") end,
    goldperorb_med = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Med"), MM:OrbValue(k2,"Med"), ">") end,
    goldperorb_mean = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Mean"), MM:OrbValue(k2,"Mean"), ">") end,
    goldperorb_max = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"Max"), MM:OrbValue(k2,"Max"), ">") end,
    goldperorb_10d_min = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Min"), MM:OrbValue(k2,"10d_Min"), ">") end,
    goldperorb_10d_med = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Med"), MM:OrbValue(k2,"10d_Med"), ">") end,
    goldperorb_10d_mean = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Mean"), MM:OrbValue(k2,"10d_Mean"), ">") end,
    goldperorb_10d_max = function(k1, k2) return MM:Compare(MM:OrbValue(k1,"10d_Max"), MM:OrbValue(k2,"10d_Max"), ">") end,
  }

  function MM:SortMysticEnchants(itemKey)
    table.sort(resultSet, sortFunctions[itemKeyToSortFunctionKey[itemKey]])
  end
end

local currentPage = 1
do -- mystic enchant page functions
  local function updatePageButtons()
    local numPages = MM:GetNumPages()
    if numPages == 0 then
      prevPageButton:Disable()
      nextPageButton:Disable()
      pageTextFrame.Text:SetText("0/0")
      return
    end
    prevPageButton:Enable()
    nextPageButton:Enable()
    if currentPage == 1 then
      prevPageButton:Disable()
    end
    if currentPage == MM:GetNumPages() then
      nextPageButton:Disable()
    end
    pageTextFrame.Text:SetText(currentPage.."/"..MM:GetNumPages())
  end

  function MM:GetNumPages()
    return math.ceil(#resultSet / numEnchantButtons)
  end

  function MM:PrevPage()
    if currentPage == 1 then return end
    currentPage = currentPage - 1
    updatePageButtons()
    self:RefreshEnchantButtons()
  end

  function MM:NextPage()
    if currentPage == self:GetNumPages() then return end
    currentPage = currentPage + 1
    updatePageButtons()
    self:RefreshEnchantButtons()
  end

  function MM:GoToPage(page)
    local numPages = self:GetNumPages()
    if page < 1 or numPages ~= 0 and page > numPages then return end
    currentPage = page
    updatePageButtons()
    self:RefreshEnchantButtons()
  end
end

do -- show/hide and select/deselect mystic enchant button functions
  local enchantQualityColors = {
    [2] = { 0.117647,        1,        0 },
    [3] = {        0, 0.439216, 0.866667 },
    [4] = { 0.639216, 0.207843, 0.933333 },
    [5] = {        1, 0.501961,        0 },
  }

  local enchantQualityBorders = {
    [2] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_green",
    [3] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Blue",
    [4] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Purple",
    [5] = AwAddonsTexturePath .. "LootTex\\Loot_Icon_Leg"
  }

  local function updateEnchantButton(enchantID, buttonNumber)
    local button = enchantButtons[buttonNumber]
    button.enchantID = enchantID
    local enchantData = MYSTIC_ENCHANTS[enchantID]
    button.IconBorder:SetTexture(enchantQualityBorders[enchantData.quality])
    local enchantName, _, enchantIcon = GetSpellInfo(enchantData.spellID)
    button.Icon:SetTexture(enchantIcon)
    button.REText:SetText(enchantName)
    
    button:SetScript("OnEnter", function(self)
      if self ~= MM:GetSelectedEnchantButton() then
        self.H:Show()
      end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
      GameTooltip:SetHyperlink("|Hspell:"..enchantData.spellID.."|h[test]|h")
      GameTooltip:Show()
    end)
    local r, g, b = unpack(enchantQualityColors[enchantData.quality])
    local mult = .3
    if IsReforgeEnchantmentKnown(enchantID) then
      button.IconBorder:SetVertexColor(1, 1, 1)
      button.Icon:SetVertexColor(1, 1, 1)
      button.BG:SetVertexColor(1, 1, 1)
      button.REText:SetTextColor(r, g, b)
    else
      button.IconBorder:SetVertexColor(mult, mult, mult)
      button.Icon:SetVertexColor(mult, mult, mult)
      button.BG:SetVertexColor(mult, mult, mult)
      button.REText:SetTextColor(mult*r, mult*g, mult*b)
    end
    button:Show()
  end

  function MM:ShowEnchantButtons()
    if #resultSet - 8 * (currentPage - 1) <= 0 then
      return
    end
    local index = 8 * (currentPage - 1) + 1
    local startIndex = index
    while index - startIndex < 8 and index <= #resultSet do
      updateEnchantButton(resultSet[index], index - startIndex + 1)
      index = index + 1
    end
  end

  function MM:HideEnchantButtons()
    for _, button in ipairs(enchantButtons) do
      button:Hide()
      button.H:SetDesaturated(true)
      button.H:Hide()
    end
    self:DeselectSelectedEnchantButton()
  end

  function MM:RefreshEnchantButtons()
    self:HideEnchantButtons()
    self:ShowEnchantButtons()
  end

  local selectedEnchantButton

  function MM:GetSelectedEnchantButton()
    return selectedEnchantButton
  end

  function MM:SetSelectedEnchantButton(button)
    button = type(button) == "table" and button or enchantButtons[button]
    local lastSelectedButton = self:GetSelectedEnchantButton()
    if lastSelectedButton == button then return end
    button.H:Show()
    button.H:SetDesaturated(false)
    if lastSelectedButton then
      lastSelectedButton.H:SetDesaturated(true)
      lastSelectedButton.H:Hide()
    end
    self:PopulateGraph(button.enchantID)
    self:ShowStatistics(button.enchantID)
    selectedEnchantButton = button
  end

  function MM:DeselectSelectedEnchantButton()
    if selectedEnchantButton then
      selectedEnchantButton.H:SetDesaturated(true)
      selectedEnchantButton.H:Hide()
    end
    self:ClearGraph()
    self:HideStatistics()
    selectedEnchantButton = nil
  end
end

do -- show/hide statistics functions
  function MM:ShowStatistics(enchantID)
    local info = MM:StatObj(enchantID)
    if info then
      statsContainerWidgets[1]:SetText("Minimum Buyout: "..(GetCoinTextureString(info.Min * 10000) or "No Data"))
      statsContainerWidgets[2]:SetText("Current Average: "..(GetCoinTextureString(info.Mean * 10000) or "No Data"))
      statsContainerWidgets[3]:SetText("10-Day Average: "..(GetCoinTextureString(info["10d_Mean"] * 10000) or "No Data"))
      statsContainerWidgets[4]:SetText("Standard Deviation: "..(GetCoinTextureString(info.Dev * 10000) or "No Data"))
      statsContainerWidgets[5]:SetText("Median: "..(GetCoinTextureString(info.Med * 10000) or "No Data"))
      statsContainerWidgets[6]:SetText("Max: "..(GetCoinTextureString(info.Max * 10000) or "No Data"))
      statsContainerWidgets[7]:SetText("Gold Per Orb: "..(GetCoinTextureString(MM:OrbValue(enchantID) * 10000) or "No Data"))
      statsContainerWidgets[8]:SetText("Last Seen: "..(MM:DaysAgoString(info.Last) or "No Data"))
      statsContainerWidgets[9]:SetText("Total Listed: "..(info.Total or "No Data"))
      statsContainerWidgets[10]:SetText("Trinkets Listed: "..(info.Trinkets or "No Data"))
      statsContainerWidgets[11]:SetText("My Listed: No Data")
      statsContainerWidgets[12]:SetText("Status: |cFF00FF00Lowest Buyout|r")
    end
  
    for i=1, #statsContainerWidgets do
      statsContainerWidgets[i].frame:Show()
    end
  end
  
  function MM:HideStatistics()
    for i=1, #statsContainerWidgets do
      statsContainerWidgets[i].frame:Hide()
    end
  end
end