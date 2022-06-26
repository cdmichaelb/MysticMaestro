local MM = LibStub("AceAddon-3.0"):GetAddon("MysticMaestro")

local scanInProgress, lastScanTime
local function remainingTime()
  if lastScanTime then
    local secondsRemaining = lastScanTime + 900 - time()
    return math.floor(secondsRemaining / 60) .. ":" .. string.format("%02d", secondsRemaining % 60)
  else
    return "Unknown"
  end
end

function MM:HandleFullScan()
  if not self:ValidateAHIsOpen() then
    return
  end
  if select(2, CanSendAuctionQuery()) then
    self:UpdateDatabase()
    scanInProgress = true
    lastScanTime = time()
    QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 0, 0, true)
  else
    MM:Print("Full scan not available. Time remaining: " .. remainingTime())
  end
end

function MM:Fullscan_AUCTION_ITEM_LIST_UPDATE()
  if scanInProgress == true then
    scanInProgress = false
    self:CollectAuctionData(lastScanTime)
  end
end

MM:RegisterEvent("AUCTION_ITEM_LIST_UPDATE", "Fullscan_AUCTION_ITEM_LIST_UPDATE")
