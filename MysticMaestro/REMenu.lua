local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

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
            local enchantName = GetSpellInfo(enchantData.spellID)
            if enchantName and enchantName:lower():find(text) then
              queryResults[enchantData.spellID] = MM:cTxt(enchantName, tostring(enchantData.quality))
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
        local key, enchantName
        if key then
          enchantName = queryResults[key]
          MM:PopulateGraph(enchantName)
          return key, enchantName
        else
          key, enchantName = next(queryResults)
          if key then
            enchantName = enchantName:match("|c........(.-)|r")
            MM:PopulateGraph(enchantName)
            return key, enchantName
          end
        end
      end,
      GetHyperlink = function(self, key)
        return "spell:" .. key
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

local standaloneMenuContainer
local function createStandaloneMenuContainer()
  standaloneMenuContainer = CreateFrame("Frame", "MysticMaestroFrameContainer", UIParent)
  standaloneMenuContainer:Hide()
  standaloneMenuContainer:EnableMouse(true)
  standaloneMenuContainer:SetMovable(true)
  standaloneMenuContainer:SetResizable(false)
  standaloneMenuContainer:SetFrameStrata("BACKGROUND")
  standaloneMenuContainer:SetBackdrop(FrameBackdrop)
  standaloneMenuContainer:SetBackdropColor(0, 0, 0, 1)
  standaloneMenuContainer:SetToplevel(true)
  standaloneMenuContainer:SetPoint("CENTER")
  standaloneMenuContainer:SetSize(635, 455)
  standaloneMenuContainer:SetClampedToScreen(true)

  -- function from WeakAuras Options for pretty border
  local function CreateDecoration(frame, width)
    local deco = CreateFrame("Frame", nil, frame)
    deco:SetSize(width, 40)

    local bg1 = deco:CreateTexture(nil, "BACKGROUND")
    bg1:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg1:SetTexCoord(0.31, 0.67, 0, 0.63)
    bg1:SetAllPoints(deco)

    local bg2 = deco:CreateTexture(nil, "BACKGROUND")
    bg2:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    bg2:SetTexCoord(0.235, 0.275, 0, 0.63)
    bg2:SetPoint("RIGHT", bg1, "LEFT", 1, 0)
    bg2:SetSize(10, 40)

    local bg3 = deco:CreateTexture(nil, "BACKGROUND")
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
      MM:CloseStandaloneMenu()
    end
  )
end

local menuContainerInitialized
local function initializeMenuContainer()
  createStandaloneMenuContainer()
  menuContainerInitialized = true
end

local mmf
local function createMenu()
  mmf = CreateFrame("Frame", "MysticMaestroFrame", UIParent)
  mmf:Hide()
  mmf:SetSize(609, 423)
  MM.MysticMaestroFrame = mmf
end

local function createContainer(parent, anchorPoint, width, height, xOffset, yOffset)
  local container = CreateFrame("Frame", nil, parent)
  container:SetResizable(false)
  container:SetFrameStrata("BACKGROUND")
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

local currencyContainer
local enchantContainerHeight = 12
local function updateCurrencyDisplay()
  currencyContainer.FontString:SetFormattedText("%s: |cFFFFFFFF%d|r %s %s: |cFFFFFFFF%d|r %s",
  "Orbs", getOrbCurrency(), CreateTextureMarkup("Interface\\Icons\\inv_custom_CollectionRCurrency", 64, 64, enchantContainerHeight+8, enchantContainerHeight+8, 0, 1, 0, 1),
  "Extracts", getExtractCurrency(), CreateTextureMarkup("Interface\\Icons\\Inv_Custom_MysticExtract", 64, 64, enchantContainerHeight+8, enchantContainerHeight+8, 0, 1, 0, 1))
end

local function createCurrencyContainer(parent)
  local width = parent:GetWidth()
  currencyContainer = CreateFrame("Frame", nil, parent)
  currencyContainer:SetSize(width, enchantContainerHeight)
  currencyContainer:SetFrameStrata("LOW")
  currencyContainer:SetPoint("BOTTOM", parent, "BOTTOM", 0, 8)
  currencyContainer.FontString = currencyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  currencyContainer.FontString:SetPoint("CENTER", currencyContainer, "CENTER")
  currencyContainer.FontString:SetSize(currencyContainer:GetWidth(), currencyContainer:GetHeight())
  updateCurrencyDisplay()
end

local function setUpCurrencyDisplay(enchantContainer)
  createCurrencyContainer(enchantContainer)
  MM:RegisterBucketEvent({"BAG_UPDATE"}, .2, updateCurrencyDisplay)
end

local menuInitialized
local enchantContainer, statsContainer, graphContainer
local function initializeMenu()
  createMenu()
  enchantContainer = createContainer(mmf, "BOTTOMLEFT", 200, 396)
  statsContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 192)
  graphContainer = createContainer(mmf, "BOTTOMRIGHT", 412, 198, 0, 198)
  MM:InitializeGraph("MysticEnchantStatsGraph", graphContainer, "BOTTOMLEFT", "BOTTOMLEFT", 8, 9, 396, 181)
  setUpCurrencyDisplay(enchantContainer)
  menuInitialized = true
end

local defaultSearchText = "|cFF777777Search|r"

local sortDropdown, filterDropdown, searchBar
local function setUpWidgets()
  sortDropdown = AceGUI:Create("Dropdown")
  sortDropdown:SetPoint("TOPLEFT", mmf, "TOPLEFT", 8, 0)
  sortDropdown:SetWidth(160)
  sortDropdown:SetHeight(27)
  sortDropdown.frame:Show()

  filterDropdown = AceGUI:Create("Dropdown")
  filterDropdown:SetPoint("TOPRIGHT", mmf, "TOPRIGHT", -6, 0)
  filterDropdown:SetWidth(160)
  filterDropdown:SetHeight(27)
  filterDropdown.frame:Show()

  searchBar = AceGUI:Create("EditBoxMysticMaestroREPredictor")
  searchBar:SetPoint("TOP", mmf, "TOP")
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

function MM:OpenStandaloneMenu()
  if not menuContainerInitialized then
    initializeMenuContainer()
  end
  if not menuInitialized then
    initializeMenu()
  end

  mmf:ClearAllPoints()
  mmf:SetPoint("BOTTOMLEFT", standaloneMenuContainer, "BOTTOMLEFT", 13, 9)
  setUpWidgets()
  self:ClearGraph()
  standaloneMenuContainer:Show()
  mmf:Show()
end

local function tearDownWidgets()
  sortDropdown:Release()
  filterDropdown:Release()
  searchBar:Release()
end

function MM:CloseStandaloneMenu()
  tearDownWidgets()
  wipe(queryResults)
  standaloneMenuContainer:Hide()
  mmf:Hide()
end
