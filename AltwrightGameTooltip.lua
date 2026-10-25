local AddonName, AltwrightNS = ...

local C = AltwrightNS.C

local recipeLib = LibStub("LibRecipes-3.0")

AltwrightNS.AltwrightGameTooltip = {}
local AltwrightGameTooltip = AltwrightNS.AltwrightGameTooltip

local GameTooltipReady = false

local function GetRecipeLevel(link)
    local AltwrightFrame = AltwrightNS.AltwrightAddon:GetMainFrame()
    AltwrightNS.AltwrightTooltip:SetOwner(AltwrightFrame, "ANCHOR_LEFT")
    AltwrightNS.AltwrightTooltip:ClearLines()
    AltwrightNS.AltwrightTooltip:SetHyperlink(link)
	
	local tooltipName = AltwrightNS.AltwrightTooltip:GetName()
	
   for i = 1, select("#", AltwrightNS.AltwrightTooltip:GetRegions()) do
      local region = select(i, AltwrightNS.AltwrightTooltip:GetRegions())
      if region and region:GetObjectType() == "FontString" then
         local tooltipText = region:GetText()
         if tooltipText then
            local _, _, rLevel = string.find(tooltipText, "%((%d+)%)")
            if rLevel then
               AltwrightNS.AltwrightTooltip:Hide()
               --print("Recipe required level: " .. rLevel)
               return tonumber(rLevel)
            end
         end
      end
   end
end

local function CreateCharacterKnownByTooltipLines(chars)
   local knownBy = {
      "Already known by:",
   }
   if chars and #chars > 0 then
      for i, char in ipairs(chars) do
         local cr, cg, cb, web = GetClassColor(char.Class.File)
         table.insert(knownBy, "\124c" .. web .. char.Name .. "\124r")
      end
      return knownBy
   end
   return nil
end

local function CreateCharacterLearnTooltipLines(charsCouldLearn, profId, requiredSkill)
   local learnedBy = {
      "Could be learned by:"
   }
   if charsCouldLearn and #charsCouldLearn > 0 then
      for i, char in ipairs(charsCouldLearn) do
         local cr, cg, cb, web = GetClassColor(char.Class.File)
         local prof = AltwrightNS.AltwrightData:GetCharacterProfession(char, profId)
         --print("prof for " .. char.Name .. ": " .. (prof and prof.Name or "nil") .. ", skill: " .. (prof and prof.Skill or "nil") .. ", requiredSkill: " .. (requiredSkill or "nil"))
         if prof and prof.Skill >= requiredSkill then
            table.insert(learnedBy, "\124c" .. web .. char.Name .. "\124r (" .. prof.Skill .. ")")
         else
            table.insert(learnedBy, "\124c" .. web .. char.Name .. "\124r (\124cnIMPOSSIBLE_DIFFICULTY_COLOR:" .. prof.Skill .. "\124r)")
         end
         
      end
      return learnedBy
   end
   return nil
end

local function CreateClassBookLearnTooltipLines(charsCouldLearn, requiredLevel)
   local learnedBy = {
      "Could be learned by:"
   }
   if charsCouldLearn and #charsCouldLearn > 0 then
      for i, char in ipairs(charsCouldLearn) do
         local cr, cg, cb, web = GetClassColor(char.Class.File)
         if char.Level >= (requiredLevel or 0) then
            table.insert(learnedBy, "\124c" .. web .. char.Name .. "\124r (" .. char.Level .. ")")
         else
            table.insert(learnedBy, "\124c" .. web .. char.Name .. "\124r (\124cnIMPOSSIBLE_DIFFICULTY_COLOR:" .. char.Level .. "\124r)")
         end
      end
      return learnedBy
   end
   return nil
end

-- adds the header line, followed by the character names 3 per line
local function AddCharacterLines(tooltip, lines)
   tooltip:AddLine(lines[1])
   local tempString = ""
   for i = 2, #lines do
      tempString = tempString .. lines[i]
      if (i-1)%3 == 0 then
         tooltip:AddLine(tempString)
         tempString = ""
      elseif i < #lines then
         tempString = tempString .. ", "
      end
   end
   if tempString ~= "" then
      tooltip:AddLine(tempString)
   end
   tooltip:AddLine(" ")
end

local function GetTooltipLines(link)
   local AltwrightFrame = AltwrightNS.AltwrightAddon:GetMainFrame()
   AltwrightNS.AltwrightTooltip:SetOwner(AltwrightFrame, "ANCHOR_LEFT")
   AltwrightNS.AltwrightTooltip:ClearLines()
   AltwrightNS.AltwrightTooltip:SetHyperlink(link)
   local lines = {}
   for i = 1, select("#", AltwrightNS.AltwrightTooltip:GetRegions()) do
      local region = select(i, AltwrightNS.AltwrightTooltip:GetRegions())
      if region and region:GetObjectType() == "FontString" then
         local text = region:GetText()
         if text then
            table.insert(lines, text)
         end
      end
   end
   AltwrightNS.AltwrightTooltip:Hide()
   return lines
end

local classesPattern = "^" .. ITEM_CLASSES_ALLOWED:gsub("%%s", "(.+)") .. "$"
local levelPattern = "^" .. ITEM_MIN_LEVEL:gsub("%%d", "(%%d+)") .. "$"

local function ClassBookTooltip_Add(tooltip, itemLink, itemName)
   local classNames, requiredLevel
   for _, line in ipairs(GetTooltipLines(itemLink)) do
      local classes = line:match(classesPattern)
      if classes then
         classNames = { strsplit(",", classes) }
         for i, className in ipairs(classNames) do
            classNames[i] = strtrim(className)
         end
      end
      local level = line:match(levelPattern)
      if level then
         requiredLevel = tonumber(level)
      end
   end
   -- books without a class restriction aren't class skill books
   if not classNames then
      return
   end

   local knownChars, couldLearnChars = AltwrightNS.AltwrightData:ClassBookKnownOrLearnable(itemName, classNames)
   local knownText = CreateCharacterKnownByTooltipLines(knownChars)
   local learnText = CreateClassBookLearnTooltipLines(couldLearnChars, requiredLevel)
   if not knownText and not learnText then
      return
   end
   tooltip:AddLine(" ")
   if knownText then
      AddCharacterLines(tooltip, knownText)
   end
   if learnText then
      AddCharacterLines(tooltip, learnText)
   end
end

local function GameTooltip_Add(tooltip, itemLink)

   if AltwrightNS.AltwrightDB.profile.settings.hideRecipeTooltips then
      return
   end

	local itemString = itemLink:match("item[%-?%d:]+")
	local _, itemId = strsplit(":", itemString)

   if not itemId or itemId == "" or itemId == "0" then
      return
   end

   local name, _, _, _, _, _, _, _, _, _, _, classId, subclassID = GetItemInfo(tonumber(itemId))
   if classId ~= C["RecipeClassId"] then
      return
   end
   if subclassID == C["BookSubclassId"] then
      ClassBookTooltip_Add(tooltip, itemLink, name)
      return
   end
   local profId = C["ProfessionSubclassIdToProfessionId"][subclassID]
   local success, spellId, createdItemId = pcall(function()
      return recipeLib:GetRecipeInfo(tonumber(itemId))
   end)
   local requiredSkill = GetRecipeLevel(itemLink)
   if success then
      if spellId or itemId then
         local knownChars, couldLearnChars, knownText, learnText
         AltwrightNS.AltwrightCache.Recipes = AltwrightNS.AltwrightCache.Recipes or {}
         if spellId then
            AltwrightNS.AltwrightCache.Recipes.Spells = AltwrightNS.AltwrightCache.Recipes.Spells or {}
            AltwrightNS.AltwrightCache.Recipes.Spells[spellId] = AltwrightNS.AltwrightCache.Recipes.Spells[spellId] or {}
            if not AltwrightNS.AltwrightCache.Recipes.Spells[spellId].knownText and not AltwrightNS.AltwrightCache.Recipes.Spells[spellId].learnText then
               knownChars, couldLearnChars = AltwrightNS.AltwrightData:CharacterProfessionRecipeKnownOrLearnable(profId, spellId, createdItemId)
               AltwrightNS.AltwrightCache.Recipes.Spells[spellId].knownText = CreateCharacterKnownByTooltipLines(knownChars)
               AltwrightNS.AltwrightCache.Recipes.Spells[spellId].learnText = CreateCharacterLearnTooltipLines(couldLearnChars, profId, requiredSkill)
            end
            knownText = AltwrightNS.AltwrightCache.Recipes.Spells[spellId].knownText or nil
            learnText = AltwrightNS.AltwrightCache.Recipes.Spells[spellId].learnText or nil
         end
         if itemId then
            AltwrightNS.AltwrightCache.Recipes.Items = AltwrightNS.AltwrightCache.Recipes.Items or {}
            AltwrightNS.AltwrightCache.Recipes.Items[itemId] = AltwrightNS.AltwrightCache.Recipes.Items[itemId] or {}
            if not AltwrightNS.AltwrightCache.Recipes.Items[itemId].knownText and not AltwrightNS.AltwrightCache.Recipes.Items[itemId].learnText then
               knownChars, couldLearnChars = knownChars, couldLearnChars or AltwrightNS.AltwrightData:CharacterProfessionRecipeKnownOrLearnable(profId, spellId, createdItemId)
               AltwrightNS.AltwrightCache.Recipes.Items[itemId].knownText = CreateCharacterKnownByTooltipLines(knownChars)
               AltwrightNS.AltwrightCache.Recipes.Items[itemId].learnText = CreateCharacterLearnTooltipLines(couldLearnChars, profId, requiredSkill)
            end
            knownText = AltwrightNS.AltwrightCache.Recipes.Items[itemId].knownText or nil
            learnText = AltwrightNS.AltwrightCache.Recipes.Items[itemId].learnText or nil
         end

         if not knownText and not learnText then
            return
         end
         tooltip:AddLine(" ")
         if knownText then
            AddCharacterLines(tooltip, knownText)
         end
         if learnText then
            AddCharacterLines(tooltip, learnText)
         end
      end
   end
end

local function GameTooltip_OnTooltipSetItem(tooltip)
   if not GameTooltipReady then
      return
   end
   GameTooltipReady = false
	local _, link = tooltip:GetItem()
	if not link then return; end
	
	GameTooltip_Add(tooltip, link)
end

local function GameTooltip_OnTooltipCleared(tooltip)
   GameTooltipReady = true
end

local function GameTooltip_SetCraftItem(tooltip, recipeIndex, reagentIndex)
	local link = GetCraftReagentItemLink(recipeIndex, reagentIndex)
	if not link then return; end
	GameTooltip_Add(tooltip, link)
end

function AltwrightGameTooltip:Initialize()
   GameTooltip:HookScript("OnTooltipSetItem", GameTooltip_OnTooltipSetItem)
   GameTooltip:HookScript("OnTooltipCleared", GameTooltip_OnTooltipCleared)
   hooksecurefunc(GameTooltip, "SetCraftItem", GameTooltip_SetCraftItem)
   GameTooltipReady = true
end