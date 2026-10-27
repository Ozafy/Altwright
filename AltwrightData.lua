local AddonName, AltwrightNS = ...

local C = AltwrightNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)
local AltwrightData = {}
AltwrightNS.AltwrightData = AltwrightData

local function AutoReturnMail(mailData)
   if mailData.Returned then
      return
   end
   local data = AltwrightNS.AltwrightDB.global.characters[mailData.Sender]
   if data then
      table.insert(data.Mail, {
         Sender = AltwrightNS.AltwrightAddon.CurrentCharacter.FullName,
         Subject = mailData.Subject,
         Body = mailData.Body,
         Time = time(),
         ArrivalTime = time(),
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = mailData.HasAttachments,
         Money = mailData.Money,
         Returned = true
      })
   end
end
local function FindInBagSlot(bags, itemId)
   for _, bag in ipairs(bags) do
      for slot=1, C_Container.GetContainerNumSlots(bag) do
         local itemID = C_Container.GetContainerItemID(bag, slot)
         if itemID == itemId then
            return true
         end
      end
   end
   return false
end
function AltwrightData:SavePlayerDataLogin()
   local name, realm = UnitFullName("player")
   local data = AltwrightNS:MergeObjects(AltwrightNS.AltwrightDB.global.characters[name .. "-" .. realm] or {}, AltwrightNS.AltwrightAddon.CurrentCharacter)
   AltwrightNS.AltwrightDB.global.characters[name .. "-" .. realm] = data
   AltwrightNS.AltwrightAddon.CurrentCharacter = data
   data.Name = name
   data.Realm = realm
   data.FullName= name .. "-" .. realm
   data.Sex = UnitSex("player")
   data.Level = UnitLevel("player")
   data.Faction = UnitFactionGroup("player")

   AltwrightData:SavePlayerItemLevel()
   AltwrightData:SavePlayerHonour()

   data.Money = GetMoney()
   data.LastLogin = time()
   data.LastLogout = data.LastLogout or time()

   local className, classFilename, classId = UnitClass("player")
   data.Class= data.Class or {}
   data.Class.Name=className
   data.Class.File=classFilename
   data.Class.Id=classId

   local raceName, raceFile, raceID = UnitRace("player")
   data.Race= data.Race or {}
   data.Race.Name=raceName
   if raceFile == "Scourge" then
      raceFile = "Undead"
   end
   data.Race.File=raceFile
   data.Race.Id=raceID

   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild= data.Guild or {}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName

   data.XP=data.XP or{}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()
   data.Resting = IsResting()
   AltwrightData:SavePlayerLocation()

   AltwrightData:SavePlayerProfessions()
   AltwrightData:SaveProfessionItemCooldowns()
   AltwrightData:SavePlayerSpells()

   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ExpiryTime < time() then
         AutoReturnMail(data.Mail[i])
         table.remove(data.Mail, i)
      end
   end

   AltwrightData:SavePlayerBags()
   AltwrightData:SavePlayerAttunements()
end

function AltwrightData:SavePlayerItemLevel()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   local overall, equipped = GetAverageItemLevel()
   data.ItemLevel = data.ItemLevel or {}
   data.ItemLevel.Overall = overall
   data.ItemLevel.Equipped = equipped
end

function AltwrightData:SavePlayerHonour()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.Rank = data.Rank or {}
   data.Rank.Value = UnitPVPRank("player")
   data.Rank.Name = GetPVPRankInfo(data.Rank.Value)
   local hk, points = GetPVPThisWeekStats()
   data.Honour = data.Honour or {}
   data.Honour.HKs = hk
   data.Honour.Points = points
end

function AltwrightData:SavePlayerBags()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.Containers = data.Containers or {}
   data.Containers.Bags = data.Containers.Bags or {}
   data.Containers.Bank = data.Containers.Bank or {}
   for bag=0, NUM_BAG_SLOTS do
      local containerSlots = C_Container.GetContainerNumSlots(bag)
      if containerSlots then
         data.Containers.Bags["bag_" .. bag] = data.Containers.Bags["bag_" .. bag] or {}
         data.Containers.Bags["bag_" .. bag].Slots = containerSlots
      end
   end
end

function AltwrightData:SavePlayerAttunements()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   local bagSlots = {}
   for bag=0, NUM_BAG_SLOTS do
      table.insert(bagSlots, bag)
   end
   data.Attunements = data.Attunements or {}
   for i, attunement in ipairs(C["Attunements"]) do
      data.Attunements[i] = data.Attunements[i] or {}
      if not data.Attunements[i].Completed then
         if attunement.type==1 then
            if attunement.attunementItem then
               local hasItem = FindInBagSlot(bagSlots, attunement.attunementItem)
               if hasItem then
                  data.Attunements[i].Completed = true
               end
            end
         elseif attunement.type==2 then
            for j=1, #attunement.attunementQuests do
               if C_QuestLog.IsQuestFlaggedCompleted(attunement.attunementQuests[j]) then
                  data.Attunements[i].Completed = true
                  break
               end
            end
         elseif attunement.type==3 then
            if attunement.attunementItem then
               local hasItem = FindInBagSlot({ KEYRING_CONTAINER }, attunement.attunementItem)
               if hasItem then
                  data.Attunements[i].Completed = true
               end
            end
         end
      end
   end
end

function AltwrightData:SavePlayerProfessions()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   -- skill events can fire before login data is set up
   if not data.FullName then
      return
   end
   data.Professions = data.Professions or {}
   data.ProfessionsSecondairy = data.ProfessionsSecondairy or {}
   local profNames_rev = tInvert(L["ProfessionIDs"])
   local skillsFound = 0
   local knownProfs = {}
   local allExpanded = true
   for i = 1, GetNumSkillLines() do
    local name, isHeader, isExpanded, skillRank, _, _, skillMaxRank = GetSkillLineInfo(i)
    if isHeader and not isExpanded then
      allExpanded = false
    end
    if profNames_rev[name] then
      local profId=profNames_rev[name]
      skillsFound = skillsFound + 1
      if C["SecondairyProfession"][profId] then
         data.ProfessionsSecondairy[profId] = data.ProfessionsSecondairy[profId] or {}
         data.ProfessionsSecondairy[profId].Name=name
         data.ProfessionsSecondairy[profId].File=C["ProfessionIcons"][profNames_rev[name]]
         data.ProfessionsSecondairy[profId].Skill=skillRank
         data.ProfessionsSecondairy[profId].SkillMax=skillMaxRank
         data.ProfessionsSecondairy[profId].Spells= data.ProfessionsSecondairy[profId].Spells or {}
         data.ProfessionsSecondairy[profId].Items= data.ProfessionsSecondairy[profId].Items or {}
      else
         table.insert(knownProfs, profId)
         data.Professions[profId] = data.Professions[profId] or {}
         data.Professions[profId].Name=name
         data.Professions[profId].File=C["ProfessionIcons"][profNames_rev[name]]
         data.Professions[profId].Skill=skillRank
         data.Professions[profId].SkillMax=skillMaxRank
         data.Professions[profId].Spells= data.Professions[profId].Spells or {}
         data.Professions[profId].Items= data.Professions[profId].Items or {}
      end
    end
   end

   -- in case a profession was unlearned, remove it from the data
   -- collapsed skill headers hide their professions, so only prune when everything is visible
   if allExpanded then
      for profId, _ in pairs(data.Professions) do
         if not tContains(knownProfs, profId) then
            data.Professions[profId] = nil
         end
      end
   end
end

function AltwrightData:ScanBank()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   local bankSlots = {
      BANK_CONTAINER,
   }
   for bag=NUM_BAG_SLOTS+1, NUM_BAG_SLOTS+NUM_BANKBAGSLOTS do
      table.insert(bankSlots, bag)
      local containerSlots = C_Container.GetContainerNumSlots(bag)
      if containerSlots then
         data.Containers.Bank["bank_" .. bag] = data.Containers.Bank["bank_" .. bag] or {}
         data.Containers.Bank["bank_" .. bag].Slots = containerSlots
      end
   end
   for i, attunement in ipairs(C["Attunements"]) do
      data.Attunements[i] = data.Attunements[i] or {}
      if not data.Attunements[i].Completed then
         if attunement.type==1 then
            if attunement.attunementItem then
               local hasItem = FindInBagSlot(bankSlots, attunement.attunementItem)
               if hasItem then
                  data.Attunements[i].Completed = true
               end
            end
         end
      end
   end
end
function AltwrightData:ClearPlayerMailData()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.Mail = data.Mail or {}
   for i=#data.Mail,1,-1 do
      if data.Mail[i].ArrivalTime < time() then
         table.remove(data.Mail, i)
      end
   end
end

function AltwrightData:SavePlayerDataLogout()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.LastLogout = time()
   -- so a wrong value read during play doesn't end up in the saved variables
   data.Money = GetMoney()
   -- IsResting() isn't reliable during logout, keep the last value seen while playing
   AltwrightData:SavePlayerLocation()
   -- /played is only requested on load, add the time played since then
   if data.TimePlayed and data.TimePlayed.Received then
      local elapsed = time() - data.TimePlayed.Received
      data.TimePlayed.Total = data.TimePlayed.Total + elapsed
      data.TimePlayed.Level = data.TimePlayed.Level + elapsed
      data.TimePlayed.Received = nil
   end
end


function AltwrightData:SavePlayerTimePlayed(total, level)
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.TimePlayed = {}
   data.TimePlayed.Total = total
   data.TimePlayed.Level = level
   data.TimePlayed.Received = time()
end

function AltwrightData:SavePlayerMoney(total, level)
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.Money = GetMoney()
end

function AltwrightData:SavePlayerXP(level)
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   -- UnitLevel still returns the old level during PLAYER_LEVEL_UP, so that event passes the new one
   data.Level = level or UnitLevel("player")
   data.XP=data.XP or{}
   data.XP.Current=UnitXP("player")
   data.XP.Needed=UnitXPMax("player")
   data.XP.Rested=GetXPExhaustion()
end

function AltwrightData:SavePlayerResting()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.Resting = IsResting()
end

function AltwrightData:SavePlayerLocation()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   data.Location = data.Location or {}
   data.Location.Zone = GetRealZoneText()
   data.Location.SubZone = GetSubZoneText()
end

function AltwrightData:SavePlayerGuild()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo("player")
   data.Guild= data.Guild or {}
   data.Guild.Name=guildName
   data.Guild.Rank=guildRankName
end

function AltwrightData:GetCharacterProfession(char, profId)
   return char.Professions[profId] or char.ProfessionsSecondairy[profId] or nil
end

local function GetSpellBookName(index)
   if GetSpellBookItemName then
      return GetSpellBookItemName(index, BOOKTYPE_SPELL)
   end
   return C_SpellBook.GetSpellBookItemName(index, Enum.SpellBookSpellBank.Player)
end

-- stores the highest known rank of every spell in the spellbook, used for the class book tooltips
function AltwrightData:SavePlayerSpells()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   local spells = {}
   for tab = 1, GetNumSpellTabs() do
      local _, _, offset, numSpells = GetSpellTabInfo(tab)
      for index = offset + 1, offset + numSpells do
         local name, subName = GetSpellBookName(index)
         if name then
            local rank = subName and tonumber(subName:match("(%d+)")) or 1
            if not spells[name] or spells[name] < rank then
               spells[name] = rank
            end
         end
      end
   end
   -- the spellbook can still be empty while loading
   if next(spells) then
      data.Spells = spells
   end
end

local romanValues = { I = 1, V = 5, X = 10, L = 50, C = 100 }

local function RomanToNumber(roman)
   local total = 0
   local previous = 0
   for i = #roman, 1, -1 do
      local value = romanValues[roman:sub(i, i)]
      if value < previous then
         total = total - value
      else
         total = total + value
         previous = value
      end
   end
   return total
end

-- class books are named after the spell they teach, with the rank as a roman numeral (e.g. Tome of Fireball XII)
function AltwrightData:ClassBookKnownOrLearnable(itemName, classNames)
   local characters = {}
   for _, name in ipairs(AltwrightNS:GetRealmCharactersSorted()) do
      local char = AltwrightNS.AltwrightDB.global.characters[name]
      if char and char.Class and tContains(classNames, char.Class.Name) then
         table.insert(characters, char)
      end
   end

   local spellName
   for _, char in ipairs(characters) do
      for name in pairs(char.Spells or {}) do
         if (not spellName or #name > #spellName) and itemName:find(name, 1, true) then
            spellName = name
         end
      end
   end
   local roman = itemName:match(" ([IVXLC]+)$")
   local rank = roman and RomanToNumber(roman) or 1

   local charactersThatKnow = {}
   local charactersThatCouldLearn = {}
   for _, char in ipairs(characters) do
      if spellName and char.Spells and char.Spells[spellName] and char.Spells[spellName] >= rank then
         table.insert(charactersThatKnow, char)
      else
         table.insert(charactersThatCouldLearn, char)
      end
   end
   return charactersThatKnow, charactersThatCouldLearn
end

function AltwrightData:CharacterProfessionRecipeKnownOrLearnable(profId, spellId, itemId)
   local characters = AltwrightNS:GetRealmCharactersSorted()
   local charactersThatKnow = {}
   local charactersThatCouldLearn = {}
   for i, name in ipairs(characters) do
      local char = AltwrightNS.AltwrightDB.global.characters[name]
      if char then
         local prof = self:GetCharacterProfession(char, profId)
         if prof then
            local known = false
            if spellId and prof.Spells and prof.Spells[spellId] then
               known = true
               table.insert(charactersThatKnow, char)
            end
            if itemId and prof.Items and prof.Items[itemId] then
               known = true
               table.insert(charactersThatKnow, char)
            end
            if not known  then
               table.insert(charactersThatCouldLearn, char)
            end
         end
      end
   end
   return charactersThatKnow, charactersThatCouldLearn
end

function AltwrightData:ScanEnchantingRecipes()
	local tradeskillName = GetCraftDisplaySkillLine()
   local profNames_rev = tInvert(L["ProfessionIDs"])
   local profId = 0
   if profNames_rev[tradeskillName] then
      profId=profNames_rev[tradeskillName]
      --print("Tradeskill Name: " .. (tradeskillName or "nil") .. ", profId: " .. (profId or "nil"))
      for i = 1, GetNumCrafts() do
         local skillName, _, skillType = GetCraftInfo(i)			-- Ex: Runed Copper Rod
         local _, _, icon, _, _, _, spellID = GetSpellInfo(skillName)		-- Gets : icon = 135225, spellID = 7421
         --print(format("name: %s, skillType: %s, spellID: %d, icon: %d", name or "nil", skillType or "nil", spellID or 0, icon or 0))
         local prof = AltwrightNS.AltwrightData:GetCharacterProfession(AltwrightNS.AltwrightAddon.CurrentCharacter, profId)
         if prof then
            prof.Spells = prof.Spells or {}
            prof.Spells[spellID] = {
               Name = skillName,
               SkillType = skillType,
               Icon = icon
            }
         end

      end
   end
end

function AltwrightData:ScanTradeSkills()
   local tradeskillName = GetTradeSkillLine()
   local profNames_rev = tInvert(L["ProfessionIDs"])
   local profId = 0
   if profNames_rev[tradeskillName] then
      profId=profNames_rev[tradeskillName]
      --print("Tradeskill Name: " .. (tradeskillName or "nil") .. ", profId: " .. (profId or "nil"))
      local numTradeSkills = GetNumTradeSkills()
      local skillName, skillType, _, _, altVerb = GetTradeSkillInfo(1)	-- test the first line and abort if not valid
      if not tradeskillName or not numTradeSkills
         or	tradeskillName == "UNKNOWN"
         or	numTradeSkills == 0
         or (skillType ~= "header" and skillType ~= "subheader") then
         return
      end

      for i = 1, numTradeSkills do
         local link
         local itemID
         skillName, skillType, _, _, altVerb = GetTradeSkillInfo(i)
         local cooldown = GetTradeSkillCooldown(i)
         link = GetTradeSkillItemLink(i)
         if link  then
            itemID = tonumber(link:match("item:(%d+)"))
         end
         if itemID and skillType ~= "header" then
            local prof = AltwrightNS.AltwrightData:GetCharacterProfession(AltwrightNS.AltwrightAddon.CurrentCharacter, profId)
            if prof then
               prof.Items = prof.Items or {}
               prof.Items[itemID] = {
                  Name = skillName,
                  SkillType = skillType,
                  Cooldown = cooldown or 0,
                  CooldownEndTime = (cooldown and cooldown>0) and (time() + cooldown) or 0
               }
            end
         end
      end
   end
end

local function HasAttachments()
	for attachmentIndex = 1, ATTACHMENTS_MAX_SEND do		-- mandatory, loop through all 12 slots, since attachments could be anywhere (ex: slot 4,5,8)
	   local item, itemID, icon, count = GetSendMailItem(attachmentIndex)
		if item then
         return true
		end
	end
   return false
end

hooksecurefunc("SendMail", function(recipient, subject, body, ...)
   local recipientName, recipientRealm = strsplit("-", recipient)
   recipientRealm = recipientRealm or GetNormalizedRealmName()
   local data = AltwrightNS.AltwrightDB.global.characters[recipientName .. "-" .. recipientRealm]
   if data then
      local attachments = HasAttachments()
      local moneySent = GetSendMailMoney()
      local arrivalTime = time()
      if moneySent>0 or attachments then
         arrivalTime = arrivalTime + (C["MailDelivery"] * 3600)
      end
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = AltwrightNS.AltwrightAddon.CurrentCharacter.FullName,
         Subject = subject,
         Body = body or "",
         Time = time(),
         ArrivalTime = arrivalTime,
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = attachments,
         Money = moneySent,
         Returned = false
      })
   end
end)

hooksecurefunc("ReturnInboxItem", function(index, ...)
	local _, stationaryIcon, mailSender, mailSubject, moneySent, _, _, numAttachments = GetInboxHeaderInfo(index)
   local recipientName, recipientRealm = strsplit("-", mailSender)
   recipientRealm = recipientRealm or GetNormalizedRealmName()
   local data = AltwrightNS.AltwrightDB.global.characters[recipientName .. "-" .. recipientRealm]
   if data then
      data.Mail = data.Mail or {}
      table.insert(data.Mail, {
         Sender = AltwrightNS.AltwrightAddon.CurrentCharacter.FullName,
         Subject = mailSubject,
         Body = "",
         Time = time(),
         ArrivalTime = time(),
         ExpiryTime = time() + C["MailExpiry"] * 86400,
         HasAttachments = numAttachments>0,
         Money = moneySent,
         Returned = true
      })
   end
end)

local GetItemCount = C_Item.GetItemCount or GetItemCount
local GetItemCooldown = C_Container.GetItemCooldown or GetItemCooldown
local GetItemInfo = C_Item.GetItemInfo or GetItemInfo

function AltwrightData:SaveProfessionItemCooldowns()
   local data = AltwrightNS.AltwrightAddon.CurrentCharacter
   for profId, items in pairs(C["ProfessionCooldownItems"]) do
      local prof = AltwrightData:GetCharacterProfession(data, profId)
      if prof then
         prof.ItemCooldowns = prof.ItemCooldowns or {}
         for _, itemId in ipairs(items) do
            -- the cooldown can only be read while the item is in the bags or equipped
            if GetItemCount(itemId) > 0 then
               local start, duration = GetItemCooldown(itemId)
               local cooldown = prof.ItemCooldowns[itemId] or {}
               cooldown.Name = GetItemInfo(itemId) or cooldown.Name
               -- ignore the global cooldown
               if start and start > 0 and duration > 1.5 then
                  cooldown.Cooldown = duration
                  cooldown.CooldownEndTime = time() + (start + duration - GetTime())
                  cooldown.ExpiredNotified = nil
               elseif cooldown.CooldownEndTime and cooldown.CooldownEndTime > time() then
                  -- only clear a cooldown that ended early, an expired one is kept for the login warning
                  cooldown.Cooldown = 0
                  cooldown.CooldownEndTime = 0
               end
               prof.ItemCooldowns[itemId] = cooldown
            end
         end
      end
   end
end

local function AddActiveCooldowns(cooldowns, items)
   if items then
      for itemId, itemData in pairs(items) do
         if itemData.Cooldown and itemData.Cooldown>0 and itemData.CooldownEndTime and itemData.CooldownEndTime>time() then
            table.insert(cooldowns, {
               Name = itemData.Name,
               Cooldown = itemData.Cooldown,
               CooldownEndTime = itemData.CooldownEndTime
            })
         end
      end
   end
end

-- calls func(char, itemData) for every profession cooldown that has expired but hasn't been used again yet
local function ForEachReadyCooldown(func, includeHidden)
   for _, name in ipairs(AltwrightNS:GetRealmCharactersSorted(includeHidden)) do
      local char = AltwrightNS.AltwrightDB.global.characters[name]
      for _, professions in ipairs({ char.Professions or {}, char.ProfessionsSecondairy or {} }) do
         for _, profession in pairs(professions) do
            for _, items in ipairs({ profession.Items or {}, profession.ItemCooldowns or {} }) do
               for _, itemData in pairs(items) do
                  if itemData.Cooldown and itemData.Cooldown>0 and itemData.CooldownEndTime and itemData.CooldownEndTime>0
                     and itemData.CooldownEndTime<=time() then
                     func(char, itemData)
                  end
               end
            end
         end
      end
   end
end

function AltwrightData:GetReadyCooldowns()
   local ready = {}
   ForEachReadyCooldown(function(char, itemData)
      table.insert(ready, { Char = char, Name = itemData.Name })
   end)
   return ready
end

local function ColoredCharacterName(char)
   local _, _, _, classColor = GetClassColor(char.Class.File)
   return "\124c" .. classColor .. char.Name .. "\124r"
end

local function PrintNotification(message)
   print("\124cffff8000" .. AddonName .. ":\124r " .. message)
end

-- warns once about every profession cooldown that expired since the last warning, returns the number of warnings
local function NotifyExpiredCooldowns()
   local count = 0
   ForEachReadyCooldown(function(char, itemData)
      if not itemData.ExpiredNotified then
         PrintNotification(string.format(L["ProfessionCooldownExpired"], ColoredCharacterName(char), "\124cnYELLOW_FONT_COLOR:" .. (itemData.Name or "?") .. "\124r"))
         itemData.ExpiredNotified = true
         count = count + 1
      end
   end, true) -- hidden characters are only hidden from the lists, their cooldowns still matter
   return count
end

-- warns about alt mail that is about to expire: once at 10 days, once at 5 days and on every login from 3 days on
-- returns the number of warnings
local function NotifyExpiringMail()
   local count = 0
   for _, name in ipairs(AltwrightNS:GetRealmCharactersSorted(true)) do
      local char = AltwrightNS.AltwrightDB.global.characters[name]
      for _, mail in ipairs(char.Mail or {}) do
         local timeLeft = mail.ExpiryTime - time()
         local threshold
         for _, days in ipairs(C["MailExpiryWarningDays"]) do
            if timeLeft <= days * 86400 then
               threshold = days
            end
         end
         -- mail past its expiry time is already gone in game, it gets cleaned up when its recipient logs in
         if timeLeft > 0 and threshold and (threshold <= C["MailExpiryWarningEveryLoginDays"] or (mail.ExpiryWarned or math.huge) > threshold) then
            local sender = AltwrightNS.AltwrightDB.global.characters[mail.Sender]
            local senderName = sender and ColoredCharacterName(sender) or mail.Sender
            local expiresIn = strtrim(AltwrightNS:LongTimeSpanToString(timeLeft))
            PrintNotification(string.format(mail.Returned and L["MailExpiringReturned"] or L["MailExpiring"], ColoredCharacterName(char), senderName, expiresIn))
            mail.ExpiryWarned = threshold
            count = count + 1
         end
      end
   end
   return count
end

local function ShowLoginAlert(message)
   RaidNotice_AddMessage(RaidWarningFrame, AddonName .. ": " .. message, { r = 1, g = 0.82, b = 0 }, 8)
end

function AltwrightData:NotifyOnLogin()
   local cooldownCount = NotifyExpiredCooldowns()
   local mailCount = NotifyExpiringMail()
   if AltwrightNS.AltwrightDB.profile.settings.hideLoginAlert or (cooldownCount == 0 and mailCount == 0) then
      return
   end
   if cooldownCount > 0 then
      ShowLoginAlert(cooldownCount == 1 and L["ProfessionCooldownReady"] or string.format(L["ProfessionCooldownsReady"], cooldownCount))
   end
   if mailCount > 0 then
      ShowLoginAlert(mailCount == 1 and L["MailExpiringAlert"] or string.format(L["MailsExpiringAlert"], mailCount))
   end
   PlaySound(SOUNDKIT.MAP_PING)
end

function AltwrightData:GetProfessionCooldowns(profession)
   local cooldowns = {}
   AddActiveCooldowns(cooldowns, profession.Items)
   AddActiveCooldowns(cooldowns, profession.ItemCooldowns)
   return cooldowns
end

local tempWorldBuffs = {}
local storeBuffTimer;
local function GetPlayerWorldBuffs()
   local worldbuffs = { };
   local i = 1;
   local name, icon, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player", i);
   while name do
      if spellId and C["WorldBuffs"][spellId] then
         worldbuffs[#worldbuffs + 1] = {
            Name = L["WorldBuffs"][spellId].name,
            Icon = icon,
            ExpirationTime = expirationTime - GetTime(),
            SpellId = spellId
         };
      end
      i = i + 1;
      name, icon, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player", i);
   end;
   tempWorldBuffs = worldbuffs
end

function AltwrightData:SpellCastStart(unit, spellId)
   if unit=="player" and spellId == 349858 then
      GetPlayerWorldBuffs()
      storeBuffTimer = C_Timer.NewTicker(1, function()
         GetPlayerWorldBuffs();
      end, 4)
   end
end

function AltwrightData:SpellCastStop(unit, spellId)
   if unit=="player" and spellId == 349858 then
      tempWorldBuffs = {}
      if storeBuffTimer then  
         storeBuffTimer:Cancel()
         storeBuffTimer = nil
      end
   end
end

function AltwrightData:SpellCastSucceeded(unit, spellId)
   if unit=="player" then
      if spellId == 349858 then
         AltwrightNS.AltwrightAddon.CurrentCharacter.WorldBuffs = tempWorldBuffs
      end
      if spellId == 349863 then
         AltwrightNS.AltwrightAddon.CurrentCharacter.WorldBuffs = {}
      end
   end
end