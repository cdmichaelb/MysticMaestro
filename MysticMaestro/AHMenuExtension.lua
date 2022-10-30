local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local AceGUI = LibStub("AceGUI-3.0")

local ahExtensionMenu

local function createContainerFrame()
  ahExtensionMenu = CreateFrame("Frame", "MysticMaestroMenuAHExtension", UIParent)
  ahExtensionMenu:SetSize(180, 378)
end

local buttonHeight = 16
local auctionScrollFrameWidth = 195

local selectedEnchantAuctionID

function MM:GetSelectedEnchantAuctionID()
  self:SetSelectedEnchantAuctionID(selectedEnchantAuctionID or {})
end

function MM:SetSelectedEnchantAuctionID(id)
  selectedEnchantAuctionID = id
end

local function createListingButton(parent, listingName)
  local listingButton = CreateFrame("Button", listingName, parent)
  listingButton:SetSize(parent:GetWidth(), buttonHeight)
  listingButton.H = listingButton:CreateTexture(nil, "OVERLAY")
  listingButton.H:SetTexture("Interface\\HelpFrame\\HelpFrameButton-Highlight")
  listingButton.H:SetAllPoints()
  listingButton.H:SetBlendMode("ADD")
  listingButton.H:SetTexCoord(0, 1, 0, 0.578125)
  listingButton.H:Hide()
  
  listingButton.price = CreateFrame("Frame", listingName.."Price", listingButton, "SmallMoneyFrameTemplate")
  MoneyFrame_SetType(listingButton.price, "AUCTION")
  listingButton.price:SetPoint("LEFT")
  listingButton.price:SetSize(parent:GetWidth(), buttonHeight)

  listingButton.price.Suffix = listingButton.price:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  listingButton.price.Suffix:SetPoint("LEFT", listingName.."PriceCopperButton", "RIGHT", 0, 0)

  listingButton:SetScript("OnClick",
    function(self)
      MM:SetSelectedEnchantAuctionID(self.id)
      for _, button in ipairs(parent.buttons) do
        if button.id ~= selectedEnchantAuctionID then
          button.H:Hide()
        end
      end
      self.H:Show()
      self.H:SetDesaturated(false)
    end
  )

  listingButton:SetScript("OnLeave",
    function(self)
      if self.id ~= selectedEnchantAuctionID then
        self.H:Hide()
      end
    end
  )

  listingButton:SetScript("OnEnter",
    function(self)
      if self.id ~= selectedEnchantAuctionID then
        self.H:Show()
        self.H:SetDesaturated(true)
      end
    end
  )

  return listingButton
end

local function createAuctionsScrollFrame(name, title, parent, numRows)
  local scrollFrame = CreateFrame("ScrollFrame", name.."ScrollFrame", parent, "FauxScrollFrameTemplate")
  scrollFrame:SetSize(auctionScrollFrameWidth - 24, buttonHeight * numRows)
  scrollFrame:SetPoint("LEFT")
  scrollFrame.Title = scrollFrame:CreateFontString(name.."Title", "OVERLAY", "GameTooltipText")
  scrollFrame.Title:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 2)
  scrollFrame.Title:SetText(title)
  scrollFrame.buttons = {}
  for i=1, numRows do
    local listingButton = createListingButton(scrollFrame, name.."Button"..i)
    listingButton:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, (1-i)*buttonHeight)
    table.insert(scrollFrame.buttons, listingButton)
  end
  return scrollFrame
end


local function myAuctionsScrollFrame_Update(self)
  -- change scroll button contents and associate results
end

local function selectEnchantAuctionsScrollFrame_Update(self)
  local buttons = self.buttons
  local results = MM:GetSelectedEnchantAuctionsResults()
  FauxScrollFrame_Update(self, #results, #buttons, buttonHeight, nil, nil, nil, nil, nil, nil, true)
  local offset = FauxScrollFrame_GetOffset(self)

  -- go through each button and set visibility and associate with results
  for line = 1, #buttons do
    local lineplusoffset = line + offset
    local button = buttons[line]
    if lineplusoffset > #results then
      button:Hide()
      button.id = nil
    else
      local result = results[lineplusoffset]
      button.price.Suffix:SetText(result.yours and "  (yours)" or nil)
      MoneyFrame_Update(button.price, result.buyoutPrice)
      button.id = result.id
      button:Show()
      if button.id == selectedEnchantAuctionID then
        button.H:Show()
        button.H:SetDesaturated(false)
      elseif button:IsMouseOver() then
        button.H:Show()
        button.H:SetDesaturated(true)
      else
        button.H:Hide()
        button.H:SetDesaturated(true)
      end
    end
  end
end








local myAuctionsScrollFrameContainer
local myAuctionsButtonCount = 8
local function createMyAuctionsScrollFrame()
  myAuctionsScrollFrameContainer = MM:CreateContainer(ahExtensionMenu, "TOPRIGHT", auctionScrollFrameWidth, buttonHeight * myAuctionsButtonCount, -11, -40)
  myAuctionsScrollFrameContainer.scrollFrame = createAuctionsScrollFrame(
    "MysticMaestroMyAuctions",
    "My Auctions",
    myAuctionsScrollFrameContainer,
    myAuctionsButtonCount)
    myAuctionsScrollFrameContainer.scrollFrame:SetScript("OnVerticalScroll",
      function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, myAuctionsScrollFrame_Update)
      end
    )
end

local selectedEnchantAuctionsScrollFrameContainer
local selectedEnchantAuctionsButtonCount = 6
local function createSelectedEnchantAuctionsScrollFrame()
  selectedEnchantAuctionsScrollFrameContainer = MM:CreateContainer(ahExtensionMenu, "BOTTOMRIGHT", auctionScrollFrameWidth, buttonHeight * selectedEnchantAuctionsButtonCount, -11, 40)
  selectedEnchantAuctionsScrollFrameContainer.scrollFrame = createAuctionsScrollFrame(
    "MysticMaestroSelectedEnchantAuctions",
    "Selected Enchant Auctions",
    selectedEnchantAuctionsScrollFrameContainer,
    selectedEnchantAuctionsButtonCount)
    selectedEnchantAuctionsScrollFrameContainer.scrollFrame:SetScript("OnVerticalScroll",
      function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, buttonHeight, selectEnchantAuctionsScrollFrame_Update)
      end
    )
end

local function initAHExtension()
  createContainerFrame()
  createMyAuctionsScrollFrame()
  createSelectedEnchantAuctionsScrollFrame()
end

function MM:ShowAHExtension()
  if not MysticMaestroMenuAHExtension then
    initAHExtension()
  end
  selectEnchantAuctionsScrollFrame_Update(selectedEnchantAuctionsScrollFrameContainer.scrollFrame)
  MysticMaestroMenuAHExtension:Show()
  MysticMaestroMenuAHExtension:ClearAllPoints()
  MysticMaestroMenuAHExtension:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", 0, 0)
  MysticMaestroMenuAHExtension:SetParent(AuctionFrame)
end

function MM:HideAHExtension()
  MysticMaestroMenuAHExtension:Hide()
  self:ClearSelectedEnchantAuctions()
end

function MM:PopulateSelectedEnchantAuctions(results)
  self:SetSelectedEnchantAuctionsResults(results)
  selectEnchantAuctionsScrollFrame_Update(selectedEnchantAuctionsScrollFrameContainer.scrollFrame)
end

function MM:ShowSelectedEnchantAuctionsButtons(results)
  local i = 1
  local buttons = selectedEnchantAuctionsScrollFrame.scrollFrame.buttons
  while (i <= #buttons and i <= #results) do
    if results[i].yours then
      MM:Print("Button " ..i.." is your listing @",GetCoinTextureString(results[i].buyoutPrice))
    end
    MoneyFrame_Update(buttons[i].price, results[i].buyoutPrice)
    buttons[i]:Show()
    i = i + 1
  end
end

local selectedEnchantAuctionsResults
function MM:GetSelectedEnchantAuctionsResults()
  self:SetSelectedEnchantAuctionsResults(selectedEnchantAuctionsResults or {})
  return selectedEnchantAuctionsResults
end

function MM:SetSelectedEnchantAuctionsResults(results)
  self:SetSelectedEnchantAuctionID(nil)
  selectedEnchantAuctionsResults = results
end

function MM:ClearSelectedEnchantAuctions()
  self:PopulateSelectedEnchantAuctions({})
end