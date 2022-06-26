local addonName, addonTable = ...

local AceAddon = LibStub("AceAddon-3.0")
local MM = AceAddon:NewAddon("MysticMaestro", "AceConsole-3.0", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local Dialog = LibStub("AceConfigDialog-3.0")

MM.OnUpdateFrame = CreateFrame("Frame")

local myOptionsTable = {
  name = "Mystic Maestro",
  handler = MM,
  type = "group",
  args = {
    enable = {
      name = "Enable",
      desc = "Enables / disables the addon",
      type = "toggle",
      set = function(info, val)
        MM.enabled = val
      end,
      get = function(info)
        return MM.enabled
      end
    } --,
    -- moreoptions={
    --   name = "More Options",
    --   type = "group",
    --   args={
    --     -- more options go here
    --   }
    -- }
  }
}

function MM:OpenMenu()
  if UnitAffectingCombat("player") then
    if Dialog.OpenFrames["Mystic Maestro"] then
      Dialog:Close("Mystic Maestro")
    end
    return
  end

  if Dialog.OpenFrames["Mystic Maestro"] then
    Dialog:Close("Mystic Maestro")
  else
    Dialog:Open("Mystic Maestro")
  end
end

LibStub("AceConfig-3.0"):RegisterOptionsTable("Mystic Maestro", myOptionsTable)

--MM:RegisterChatCommand("mm","OpenMenu")

local defaults = {
  profile = {
    optionA = true,
    optionB = false,
    suboptions = {
      subOptionA = false,
      subOptionB = true
    }
  }
}

function MM:RefreshConfig()
  -- would do some stuff here
end

local GetSpellInfo = GetSpellInfo

local enchantMT = {
  __index = function(t, k)
    if type(k) == "number" then
      return t[GetSpellInfo(k)]
    elseif type(k) == "string" then
      local newListing = {}
      t[k] = newListing
      return newListing
    end
  end
}

function MM:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("MysticMaestroDB")
  if self.db.realm.RE_AH_LISTINGS then
    self:UpdateDatabase()
  end
end

function MM:ProcessSlashCommand(input)
  local lowerInput = input:lower()
  if lowerInput:match("^fullscan$") then
    MM:HandleFullScan()
  elseif lowerInput:match("^slowscan") then
    MM:HandleSlowScan(input:match("^%w+%s+(.+)"))
  elseif lowerInput:match("^graph") then
    MM:HandleGraph(input:match("^%w+%s+(.+)"))
  else
    MM:Print("Command not recognized")
  end
end

MM:RegisterChatCommand("mm", "ProcessSlashCommand")

function MM:TooltipHandler(tooltip, ...)
  -- print(tooltip:GetItem())
  tooltip:AddDoubleLine("Mystic", "Maestro")
end

GameTooltip:HookScript(
  "OnTooltipSetItem",
  function(...)
    MM:TooltipHandler(...)
  end
)
