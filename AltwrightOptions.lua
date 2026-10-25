local AddonName, AltwrightNS = ...

local C = AltwrightNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local Altwrighticon = LibStub("LibDBIcon-1.0")
local AltwrightOptionsCategory, AltwrightOptionsLayout = Settings.RegisterVerticalLayoutCategory(AddonName)
local AltwrightHideCharacterCategory, AltwrightHideCharacterLayout = Settings.RegisterVerticalLayoutSubcategory(AltwrightOptionsCategory, L["OptionHideCharacter"])


local AltwrightOptions = {}
AltwrightNS.AltwrightOptions = AltwrightOptions
AltwrightNS.AltwrightOptions.Category = AltwrightOptionsCategory
AltwrightNS.AltwrightOptions.Layout = AltwrightOptionsLayout
AltwrightNS.AltwrightOptions.HideCharacterCategory = AltwrightHideCharacterCategory
AltwrightNS.AltwrightOptions.HideCharacterLayout = AltwrightHideCharacterLayout

local function OnMinimapSettingChanged(setting, value)
   if value then
      Altwrighticon:Hide(AddonName)
   else
      Altwrighticon:Show(AddonName)
   end
end

local charToDelete = ""

local function GetCharacterToDelete()
   return charToDelete
end

local function SetCharacterToDelete(value)
   charToDelete = value
end

local function GetAllCharactersSortedByRealm()
   local characterNames = {}
   for key, char in pairs(AltwrightNS.AltwrightDB.global.characters) do
         table.insert(characterNames, char.Realm .. "-" .. char.Name)
   end
   table.sort(characterNames)

   return characterNames
end

local function GetAllCharactersSortedByRealmContainer()
   local characterNames = GetAllCharactersSortedByRealm()

   local container = Settings.CreateControlTextContainer()
   container:Add("", L["OptionSelectCharacter"])
   for i, char in ipairs(characterNames) do
         container:Add(char, char)
   end
   return container:GetData()
end

local function DeleteCharacter()
   if charToDelete == "" then
      return
   else
      local realm, name = strsplit("-", charToDelete, 2)
      local char = AltwrightNS.AltwrightDB.global.characters[name .. "-" .. realm]
      if char == nil then
         print("Character '" .. name .. "' from realm '" .. realm .. "' not found in Altwright database.")
         Settings.SetValue("Altwright_Character_To_Delete", "")
         return
      end
      local cr, cg, cb, web = GetClassColor(char.Class.File)
      print("Deleting '\124c" .. web .. name .. "\124r' from realm '" .. realm .. "' from Altwright database.")
      AltwrightNS.AltwrightDB.global.characters[name .. "-" .. realm] = nil
      Settings.SetValue("Altwright_Character_To_Delete", "")
   end
end

function CreateOptionsCategory()
    local name = L["OptionsSettingsHeader"];
    local data = { name = name };
    local initializer = Settings.CreateSettingInitializer("SettingsListSectionHeaderTemplate", data);
    AltwrightOptionsLayout:AddInitializer(initializer);

	local minimapSetting = Settings.RegisterAddOnSetting(
      AltwrightOptionsCategory,
      "Altwright_Minimap_Toggle",
      "hide",
      AltwrightNS.AltwrightDB.profile.minimap,
      Settings.VarType.Boolean,
      L["OptionMinimap"],
      Settings.Default.False
   )
	minimapSetting:SetValueChangedCallback(OnMinimapSettingChanged)
	Settings.CreateCheckbox(AltwrightOptionsCategory, minimapSetting, L["OptionMinimap"])

	local tooltipSetting = Settings.RegisterAddOnSetting(
      AltwrightOptionsCategory,
      "Altwright_Tooltip_Toggle",
      "hideRecipeTooltips",
      AltwrightNS.AltwrightDB.profile.settings,
      Settings.VarType.Boolean,
      L["OptionTooltip"],
      Settings.Default.False
   )
	Settings.CreateCheckbox(AltwrightOptionsCategory, tooltipSetting, L["OptionTooltipText"])

	local loginAlertSetting = Settings.RegisterAddOnSetting(
      AltwrightOptionsCategory,
      "Altwright_LoginAlert_Toggle",
      "hideLoginAlert",
      AltwrightNS.AltwrightDB.profile.settings,
      Settings.VarType.Boolean,
      L["OptionLoginAlert"],
      Settings.Default.False
   )
	Settings.CreateCheckbox(AltwrightOptionsCategory, loginAlertSetting, L["OptionLoginAlertText"])

    local name = L["OptionsDeleteHeader"];
    local data = { name = name };
    local initializer = Settings.CreateSettingInitializer("SettingsListSectionHeaderTemplate", data);
    AltwrightOptionsLayout:AddInitializer(initializer);

	local deleteCharacterSetting = Settings.RegisterProxySetting(
		AltwrightOptionsCategory,
		"Altwright_Character_To_Delete",
		Settings.VarType.String,
		L["OptionSelectCharacterToDelete"],
		"",
		GetCharacterToDelete,
		SetCharacterToDelete
	)
	Settings.CreateDropdown(AltwrightOptionsCategory, deleteCharacterSetting, GetAllCharactersSortedByRealmContainer)

	local deleteButtonInitializer = CreateSettingsButtonInitializer(
		L["OptionDeleteSelected"], -- name
		L["OptionDelete"], -- buttonText
		DeleteCharacter,
		L["OptionDeleteTooltip"],
		true,
		nil,
		nil
	)

	local addonLayout = SettingsPanel:GetLayout(AltwrightOptionsCategory)
	addonLayout:AddInitializer(deleteButtonInitializer)

   Settings.RegisterAddOnCategory(AltwrightOptionsCategory)
end

function CreateHideCharacterCategory()
   local characters = GetAllCharactersSortedByRealm();
   for i, name in ipairs(characters) do
      local realm, name = strsplit("-", name, 2)
      local char = name .. "-" .. realm
      local hideCharacterSetting = Settings.RegisterAddOnSetting(
         AltwrightHideCharacterCategory,
         "Altwright_Character_To_Hide" .. i,
         char,
         AltwrightNS.AltwrightDB.global.hiddenCharacters,
         Settings.VarType.Boolean,
         char,
         Settings.Default.False
      )
      Settings.CreateCheckbox(AltwrightHideCharacterCategory, hideCharacterSetting, L["OptionHideCharacterTooltipText"])
   end
   Settings.RegisterAddOnCategory(AltwrightHideCharacterCategory)
end

function AltwrightOptions:Initialize()
      CreateOptionsCategory()
      CreateHideCharacterCategory()
end