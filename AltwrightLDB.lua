local AddonName, AltwrightNS = ...

local C = AltwrightNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltwrightLDB = LibStub("LibDataBroker-1.1"):NewDataObject(AddonName, {  
	type = "data source",  
	text = AddonName,  
	icon = "Interface\\Icons\\inv_scroll_03",  
	OnClick = function() AltwrightNS.AltwrightAddon.ToggleFrame() end,  
}) 
AltwrightNS.AltwrightLDB = AltwrightLDB

function AltwrightLDB:OnTooltipShow(tooltip)
   self:AddLine(AddonName, 255, 255, 255)
   self:AddLine(" ")
   local readyCooldowns = AltwrightNS.AltwrightData:GetReadyCooldowns()
   if #readyCooldowns > 0 then
      self:AddLine(L["ProfessionCooldownsReadyHeader"] .. ":")
      for _, cooldown in ipairs(readyCooldowns) do
         local cr, cg, cb = GetClassColor(cooldown.Char.Class.File)
         self:AddDoubleLine(cooldown.Char.Name, cooldown.Name or "?", cr, cg, cb, 1, 0.82, 0)
      end
      self:AddLine(" ")
   end
   self:AddLine(L["Gold"] .. ":")
   local totalmoney = 0
   local characters = AltwrightNS:GetRealmCharactersSorted()
   for i, name in ipairs(characters) do
      local char = AltwrightNS.AltwrightDB.global.characters[name]
      local factionIcon, raceIcon, classIcon, showRank = AltwrightNS:GetCharacterIcons(char)
      local money = char.Money
      totalmoney = totalmoney + money
      local cr, cg, cb, ca = GetClassColor(char.Class.File)
      self:AddDoubleLine("|T"..factionIcon..":0|t" .. "|T"..raceIcon..":0|t".. "|T"..classIcon..":0|t" .. " " .. char.Name .. " (" .. char.Level .. ")", AltwrightNS:MoneyToGoldString(char.Money), cr, cg, cb)
   end
   self:AddLine(" ")
   self:AddDoubleLine(L["Total"], AltwrightNS:MoneyToGoldString(totalmoney))
   self:AddTexture("Interface\\Icons\\Inv_misc_coin_02")
end

function AltwrightLDB:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
	GameTooltip:ClearLines()
	GameTooltip:Show()
end

function AltwrightLDB:OnLeave()
	GameTooltip:Hide()
end