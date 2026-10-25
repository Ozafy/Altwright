local AddonName, AltwrightNS = ...

local C = AltwrightNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltwrightDB = AltwrightNS.AltwrightDB
local AltwrightLDB = AltwrightNS.AltwrightLDB

local icon = LibStub("LibDBIcon-1.0")

local AltwrightFrame

AltwrightNS.AltwrightCache = {}

local AltwrightAddon = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceEvent-3.0", "AceTimer-3.0")
AltwrightNS.AltwrightAddon = AltwrightAddon

local pendingTimers = {}
-- (re)starts a timer for key, so a burst of events results in a single call
local function ScheduleOnce(key, func, delay)
   if pendingTimers[key] then
      AltwrightAddon:CancelTimer(pendingTimers[key])
   end
   pendingTimers[key] = AltwrightAddon:ScheduleTimer(function()
      pendingTimers[key] = nil
      -- events can fire during loading, before the character data is set up
      if AltwrightAddon.CurrentCharacter.FullName then
         func()
      end
   end, delay)
end

local bankOpen = false

local function BagsChanged()
   AltwrightNS.AltwrightData:SavePlayerBags()
   AltwrightNS.AltwrightData:SavePlayerItemLevel() -- overall item level includes items in bags
   AltwrightNS.AltwrightData:SavePlayerAttunements()
   if bankOpen then
      AltwrightNS.AltwrightData:ScanBank()
   end
end

SLASH_ALTWRIGHT1, SLASH_ALTWRIGHT2, SLASH_ALTWRIGHT3 = "/alt", "/altwright", "/altinator"

SlashCmdList.ALTWRIGHT = function(msg, editBox)
   if msg == "options" or msg == "o" then
      Settings.OpenToCategory(AltwrightNS.AltwrightOptions.Category:GetID())
   else
      AltwrightAddon:ToggleFrame()
   end
end

function AltwrightAddon:OnInitialize()
   -- Altwright used to be called Altinator, the Altinator stub addon loads the old saved variables so they can be copied over
   if _G.AltwrightDB == nil and type(_G.AltinatorDB) == "table" then
      _G.AltwrightDB = CopyTable(_G.AltinatorDB)
      print("\124cffff8000" .. AddonName .. ":\124r " .. L["ImportedAltinatorSettings"])
   end
	AltwrightDB = LibStub("AceDB-3.0"):New("AltwrightDB", {
		profile = {
			minimap = {
				hide = false,
			},
         settings = {
            hideRecipeTooltips = false,
            hideLoginAlert = false,
         }
		},
      global = {
         characters = {},
         hiddenCharacters = {}
      }
	})
   AltwrightNS.AltwrightDB = AltwrightDB
	icon:Register(AddonName, AltwrightLDB, AltwrightDB.profile.minimap)
   if AltwrightDB.global.dbversion ~= C["MajorDBVersion"] then
      AltwrightDB.global.characters = {}
      AltwrightDB.global.hiddenCharacters = {}
      AltwrightDB.global.dbversion = C["MajorDBVersion"]
   end
   AltwrightAddon.CurrentCharacter = {}
   self:RegisterEvent("PLAYER_ENTERING_WORLD")
   self:RegisterEvent("PLAYER_LOGOUT")
   self:RegisterEvent("TIME_PLAYED_MSG")
   self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
   self:RegisterEvent("PLAYER_MONEY")
   self:RegisterEvent("PLAYER_LEVEL_UP")
   self:RegisterEvent("PLAYER_XP_UPDATE")
   self:RegisterEvent("PLAYER_UPDATE_RESTING")
   self:RegisterEvent("ZONE_CHANGED")
   self:RegisterEvent("ZONE_CHANGED_INDOORS")
   self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
   self:RegisterEvent("PLAYER_GUILD_UPDATE")
   self:RegisterEvent("TRADE_SKILL_SHOW")
   self:RegisterEvent("TRADE_SKILL_UPDATE")
   self:RegisterEvent("CRAFT_UPDATE")
   self:RegisterEvent("CHAT_MSG_SKILL")
   self:RegisterEvent("SKILL_LINES_CHANGED")
   self:RegisterEvent("SPELLS_CHANGED")
   self:RegisterEvent("BANKFRAME_OPENED")
   self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
   self:RegisterEvent("BAG_UPDATE_DELAYED")
   self:RegisterEvent("BAG_UPDATE_COOLDOWN")
   self:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
   self:RegisterEvent("BANKFRAME_CLOSED")
   self:RegisterEvent("PLAYER_PVP_KILLS_CHANGED")
   self:RegisterEvent("PLAYER_PVP_RANK_CHANGED")
   self:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
   self:RegisterEvent("QUEST_TURNED_IN")
   self:RegisterEvent("UNIT_SPELLCAST_START")
   self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
   self:RegisterEvent("UNIT_SPELLCAST_STOP")
   self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
   AltwrightNS.AltwrightOptions:Initialize()
   RequestTimePlayed()
   AltwrightNS.AltwrightGameTooltip:Initialize()
end

function AltwrightAddon:OnDisable()
   self:UnregisterEvent("PLAYER_ENTERING_WORLD")
   self:UnregisterEvent("PLAYER_LOGOUT")
   self:UnregisterEvent("TIME_PLAYED_MSG")
   self:UnregisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
   self:UnregisterEvent("PLAYER_MONEY")
   self:UnregisterEvent("PLAYER_LEVEL_UP")
   self:UnregisterEvent("PLAYER_XP_UPDATE")
   self:UnregisterEvent("PLAYER_UPDATE_RESTING")
   self:UnregisterEvent("ZONE_CHANGED")
   self:UnregisterEvent("ZONE_CHANGED_INDOORS")
   self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
   self:UnregisterEvent("PLAYER_GUILD_UPDATE")
   self:UnregisterEvent("TRADE_SKILL_SHOW")
   self:UnregisterEvent("TRADE_SKILL_UPDATE")
   self:UnregisterEvent("CRAFT_UPDATE")
   self:UnregisterEvent("CHAT_MSG_SKILL")
   self:UnregisterEvent("SKILL_LINES_CHANGED")
   self:UnregisterEvent("SPELLS_CHANGED")
   self:UnregisterEvent("BANKFRAME_OPENED")
   self:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
   self:UnregisterEvent("BAG_UPDATE_DELAYED")
   self:UnregisterEvent("BAG_UPDATE_COOLDOWN")
   self:UnregisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
   self:UnregisterEvent("BANKFRAME_CLOSED")
   self:UnregisterEvent("PLAYER_PVP_KILLS_CHANGED")
   self:UnregisterEvent("PLAYER_PVP_RANK_CHANGED")
   self:UnregisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN")
   self:UnregisterEvent("QUEST_TURNED_IN")
   self:UnregisterEvent("UNIT_SPELLCAST_START")
   self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
   self:UnregisterEvent("UNIT_SPELLCAST_STOP")
   self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function AltwrightAddon:PLAYER_ENTERING_WORLD(self, isLogin, isReload)
   if isLogin or isReload then
      AltwrightNS.AltwrightData:SavePlayerDataLogin()
   end
   if isLogin then
      AltwrightAddon:ScheduleTimer(AltwrightNS.AltwrightData.NotifyOnLogin, 5)
   end
   -- IsResting() can still be false right after loading in, check again once the world is settled
   ScheduleOnce("resting", AltwrightNS.AltwrightData.SavePlayerResting, 3)
end

function AltwrightAddon:PLAYER_LOGOUT()
   AltwrightNS.AltwrightData:SavePlayerDataLogout()
end

function AltwrightAddon:PLAYER_INTERACTION_MANAGER_FRAME_HIDE(self, type)
   if(type == 17) then
      AltwrightNS.AltwrightData:ClearPlayerMailData()
   end
end

function AltwrightAddon:TIME_PLAYED_MSG(self, total, level)
	AltwrightNS.AltwrightData:SavePlayerTimePlayed(total, level)
end

function AltwrightAddon:PLAYER_MONEY()
   AltwrightNS.AltwrightData:SavePlayerMoney()
end

function AltwrightAddon:PLAYER_LEVEL_UP(event, level)
   AltwrightNS.AltwrightData:SavePlayerXP(level)
end

function AltwrightAddon:PLAYER_XP_UPDATE()
   AltwrightNS.AltwrightData:SavePlayerXP()
end

function AltwrightAddon:PLAYER_UPDATE_RESTING()
   AltwrightNS.AltwrightData:SavePlayerResting()
end

function AltwrightAddon:ZONE_CHANGED()
   ScheduleOnce("location", AltwrightNS.AltwrightData.SavePlayerLocation, 0.5)
   ScheduleOnce("resting", AltwrightNS.AltwrightData.SavePlayerResting, 0.5)
end

function AltwrightAddon:ZONE_CHANGED_INDOORS()
   ScheduleOnce("location", AltwrightNS.AltwrightData.SavePlayerLocation, 0.5)
   ScheduleOnce("resting", AltwrightNS.AltwrightData.SavePlayerResting, 0.5)
end

function AltwrightAddon:ZONE_CHANGED_NEW_AREA()
   ScheduleOnce("location", AltwrightNS.AltwrightData.SavePlayerLocation, 0.5)
end

function AltwrightAddon:PLAYER_GUILD_UPDATE()
   AltwrightNS.AltwrightData:SavePlayerGuild()
end

function AltwrightAddon:TRADE_SKILL_SHOW()
   ScheduleOnce("tradeSkills", AltwrightNS.AltwrightData.ScanTradeSkills, 0.5)
end

-- TRADE_SKILL_UPDATE fires in bursts (crafting, bag changes, filtering), so rescan once things settle
-- this picks up skill ups (recipe colors) and cooldowns started by crafting
function AltwrightAddon:TRADE_SKILL_UPDATE()
   ScheduleOnce("tradeSkills", AltwrightNS.AltwrightData.ScanTradeSkills, 0.5)
end

function AltwrightAddon:CHAT_MSG_SKILL()
   ScheduleOnce("professions", AltwrightNS.AltwrightData.SavePlayerProfessions, 0.5)
end

function AltwrightAddon:SKILL_LINES_CHANGED()
   ScheduleOnce("professions", AltwrightNS.AltwrightData.SavePlayerProfessions, 0.5)
end

function AltwrightAddon:SPELLS_CHANGED()
   ScheduleOnce("spells", AltwrightNS.AltwrightData.SavePlayerSpells, 1)
end

function AltwrightAddon:CRAFT_UPDATE()
   AltwrightAddon:ScheduleTimer(AltwrightNS.AltwrightData.ScanEnchantingRecipes, 0.5)	
end

function AltwrightAddon:BANKFRAME_OPENED()
   bankOpen = true
   AltwrightAddon:ScheduleTimer(AltwrightNS.AltwrightData.ScanBank, 0.5)	
end

function AltwrightAddon:BANKFRAME_CLOSED()
   bankOpen = false
end

function AltwrightAddon:PLAYERBANKBAGSLOTS_CHANGED()
   ScheduleOnce("bank", AltwrightNS.AltwrightData.ScanBank, 0.5)
end

function AltwrightAddon:BAG_UPDATE_DELAYED()
   ScheduleOnce("bags", BagsChanged, 0.5)
end

function AltwrightAddon:BAG_UPDATE_COOLDOWN()
   ScheduleOnce("itemCooldowns", AltwrightNS.AltwrightData.SaveProfessionItemCooldowns, 0.5)
end

function AltwrightAddon:PLAYER_EQUIPMENT_CHANGED()
   ScheduleOnce("itemLevel", AltwrightNS.AltwrightData.SavePlayerItemLevel, 0.5)
end

function AltwrightAddon:PLAYER_PVP_KILLS_CHANGED()
   ScheduleOnce("honour", AltwrightNS.AltwrightData.SavePlayerHonour, 1)
end

function AltwrightAddon:PLAYER_PVP_RANK_CHANGED()
   ScheduleOnce("honour", AltwrightNS.AltwrightData.SavePlayerHonour, 1)
end

function AltwrightAddon:CHAT_MSG_COMBAT_HONOR_GAIN()
   ScheduleOnce("honour", AltwrightNS.AltwrightData.SavePlayerHonour, 1)
end

-- the quest isn't always flagged as completed yet when this fires
function AltwrightAddon:QUEST_TURNED_IN()
   ScheduleOnce("attunements", AltwrightNS.AltwrightData.SavePlayerAttunements, 1)
end

function AltwrightAddon:UNIT_SPELLCAST_START(event, unit, castGUID, spellId)
   AltwrightNS.AltwrightData:SpellCastStart(unit, spellId)
end

function AltwrightAddon:UNIT_SPELLCAST_INTERRUPTED(event, unit, castGUID, spellId)
   AltwrightNS.AltwrightData:SpellCastStop(unit, spellId)
end

function AltwrightAddon:UNIT_SPELLCAST_STOP(event, unit, castGUID, spellId)
   AltwrightNS.AltwrightData:SpellCastStop(unit, spellId)
end

function AltwrightAddon:UNIT_SPELLCAST_SUCCEEDED(event, unit, castGUID, spellId)
   AltwrightNS.AltwrightData:SpellCastSucceeded(unit, spellId)
end

function AltwrightAddon:GetMainFrame()
   return AltwrightFrame or AltwrightAddon:CreateMainFrame()
end

function AltwrightAddon:ToggleFrame()
   local frame = AltwrightAddon:GetMainFrame()
   frame:SetShown(not frame:IsShown())
   if frame:IsShown() then
      for i = 1, #AltwrightNS.Tabs do
         local tab = AltwrightNS.Tabs[i]
         if tab.content:IsShown() and tab.content.Refresh then
            tab.content:Refresh(tab.content)
         end
      end
   end
end

local function Tab_OnClick(self)
   PanelTemplates_SetTab(self:GetParent(), self:GetID())

   for i = 1, #AltwrightNS.Tabs do
      local tab = AltwrightNS.Tabs[i]
      if tab.content:IsShown() then
         tab.content:Hide()
      end
   end
   SetTitle("Altwright - " .. self.Name)
   self.content:LoadContent(self.content)
   self.content:Show()
end

local function CreateTabs(frame,  ...)
   local args = {...}
   AltwrightNS.Tabs = AltwrightNS.Tabs or {}
   local frameName = frame:GetName()
   for i, name in ipairs(args) do
      local tab = CreateFrame("Button", frameName.."Tab"..i, frame, "CharacterFrameTabButtonTemplate")
      tab:SetID(i)
      tab:SetText(name)
      tab.Name = name
      tab:SetScript("OnClick", Tab_OnClick)

      tab.content = CreateFrame("Frame", nil, frame)      
      tab.content:SetSize(C["Width"], C["Height"])
      tab.content:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -28)
      tab.content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 6)
      tab.content:Hide()
      
      table.insert(AltwrightNS.Tabs, tab)

      if(i==1) then
         tab:SetPoint("TOPLEFT", AltwrightFrame, "BOTTOMLEFT", 0, 2)
      else
         tab:SetPoint("TOPLEFT", AltwrightNS.Tabs[i-1], "TOPRIGHT", -14, 0)
      end
   end
   frame.numTabs = #AltwrightNS.Tabs
   return unpack(AltwrightNS.Tabs)
end

function SetTitle(title)
   AltwrightFrame.Title:SetText(title)
end

function AltwrightAddon:CreateMainFrame()
   AltwrightFrame = CreateFrame("Frame", "AltwrightFrame", UIParent, "BasicFrameTemplateWithInset")
   AltwrightFrame:SetSize(C["Width"], C["Height"])
   AltwrightFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
   AltwrightFrame:SetToplevel(true)
   AltwrightFrame:SetClampedToScreen(true)
   AltwrightFrame:EnableMouse(true)
   AltwrightFrame:SetMovable(true)
   AltwrightFrame:RegisterForDrag("LeftButton")
   AltwrightFrame:SetScript("OnDragStart", function(self)
      AltwrightFrame:StartMoving()
   end)
   AltwrightFrame:SetScript("OnDragStop", function(self)
      AltwrightFrame:StopMovingOrSizing()
   end)

   AltwrightFrame:SetScript("OnShow", function()
         PlaySound(808)
   end)

   AltwrightFrame:SetScript("OnHide", function()
         PlaySound(808)
   end)

   AltwrightNS.AltwrightTooltip = CreateFrame("GameTooltip", "AltwrightTooltipFrame", AltwrightFrame, "GameTooltipTemplate")
   AltwrightNS.AltwrightTooltip:SetFrameStrata("TOOLTIP")

   AltwrightFrame.TitleBg:SetHeight(30)
   AltwrightFrame.Title = AltwrightFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
   AltwrightFrame.Title:SetPoint("CENTER", AltwrightFrame.TitleBg, "CENTER", 0, 6)
   SetTitle(AddonName)

   AltwrightFrame.OptionsButton = AltwrightFrame.OptionsButton or CreateFrame("Button", nil, AltwrightFrame, "GameMenuButtonTemplate");
   AltwrightFrame.OptionsButton:SetPoint("TOPRIGHT", AltwrightFrame, "TOPRIGHT", -23, 2);
   AltwrightFrame.OptionsButton:SetSize(24, 24);
   AltwrightFrame.OptionsButton:SetText("|TInterface\\Buttons\\UI-OptionsButton:0|t");
   AltwrightFrame.OptionsButton:SetNormalFontObject("GameFontNormal");
   AltwrightFrame.OptionsButton:SetHighlightFontObject("GameFontHighlight");
   AltwrightFrame.OptionsButton:SetScript("OnClick", function(button)
      Settings.OpenToCategory(AltwrightNS.AltwrightOptions.Category:GetID())
   end)

   local overView, activityView, professionView, gearView, AttunementView, searchView = CreateTabs(AltwrightFrame, L["Overview"], L["Activity"], L["Professions"], L["Gear"], L["Attunement"], L["Search"])
   overView.content.LoadContent = AltwrightNS.AltwrightOverviewFrame.Initialize
   overView.content.Refresh = AltwrightNS.AltwrightOverviewFrame.Initialize
   activityView.content.LoadContent = AltwrightNS.AltwrightActivityFrame.Initialize
   activityView.content.Refresh = AltwrightNS.AltwrightActivityFrame.Initialize
   professionView.content.LoadContent = AltwrightNS.AltwrightProfessionFrame.Initialize
   professionView.content.Refresh = AltwrightNS.AltwrightProfessionFrame.Initialize
   gearView.content.LoadContent = AltwrightNS.AltwrightGearFrame.Initialize
   gearView.content.Refresh = AltwrightNS.AltwrightGearFrame.Initialize
   AttunementView.content.LoadContent = AltwrightNS.AltwrightAttunementFrame.Initialize
   AttunementView.content.Refresh = AltwrightNS.AltwrightAttunementFrame.Initialize
   searchView.content.LoadContent = AltwrightNS.AltwrightSearchFrame.Initialize


   Tab_OnClick(overView)
   tinsert(UISpecialFrames, "AltwrightFrame");
   AltwrightFrame:Hide()
   return AltwrightFrame
end


