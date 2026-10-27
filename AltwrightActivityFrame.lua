local AddonName, AltwrightNS = ...

local C = AltwrightNS.C
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

local AltwrightActivityFrame = {}
AltwrightNS.AltwrightActivityFrame = AltwrightActivityFrame

function AltwrightActivityFrame:Initialize(self)
    if Syndicator and Syndicator.API.IsReady() then
        local _PADDING = 5
        local _ICON_SIZE = 15
        local _HEIGHT = _ICON_SIZE + 5

        local data = AltwrightNS.AltwrightAddon.CurrentCharacter

        self.NameHeader = self.NameHeader or self:CreateFontString("HeaderName", "ARTWORK", "GameFontHighlight")
        self.NameHeader:SetPoint("TOPLEFT", _PADDING, -10)
        self.NameHeader:SetText(L["Characters"])

        self.MailHeader = self.MailHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.MailHeader:SetPoint("LEFT", self.NameHeader, "LEFT", 165, 0)
        self.MailHeader:SetText(L["Mail"])

        self.AuctionsHeader = self.AuctionsHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.AuctionsHeader:SetPoint("LEFT", self.MailHeader, "LEFT", 100, 0)
        self.AuctionsHeader:SetText(L["Auctions"])

        self.PlayedHeader = self.PlayedHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.PlayedHeader:SetPoint("LEFT", self.AuctionsHeader, "LEFT", 125, 0)
        self.PlayedHeader:SetText(L["Played"])

        self.LastLogoutHeader = self.LastLogoutHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.LastLogoutHeader:SetPoint("LEFT", self.PlayedHeader, "LEFT", 125, 0)
        self.LastLogoutHeader:SetText(L["LastLogout"])

        self.BoonedHeader = self.BoonedHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.BoonedHeader:SetPoint("LEFT", self.LastLogoutHeader, "LEFT", 125, 0)
        self.BoonedHeader:SetText(L["BoonedBuffs"])

        self.HonourHeader = self.HonourHeader or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.HonourHeader:SetPoint("LEFT", self.BoonedHeader, "LEFT", 125, 0)
        self.HonourHeader:SetText(L["Honour"])

        local scrollFrame = self.ScrollFrame or AltwrightNS:CreateScrollFrame(self)
        AltwrightNS:HideRowWidgets(scrollFrame.content)

        local currentTime = time()
        local totalCharacters = 0
        local totalMail = 0
        local totalAuctions = 0
        local totalAuctionItems = 0
        local totalPlayed = 0
        local characters = AltwrightNS:GetRealmCharactersSorted()
        scrollFrame.content.FactionIcons = scrollFrame.content.FactionIcons or {}
        scrollFrame.content.RaceIcons = scrollFrame.content.RaceIcons or {}
        scrollFrame.content.ClassIcons = scrollFrame.content.ClassIcons or {}
        scrollFrame.content.CharNames = scrollFrame.content.CharNames or {}
        scrollFrame.content.MailTexts = scrollFrame.content.MailTexts or {}
        scrollFrame.content.AuctionTexts = scrollFrame.content.AuctionTexts or {}
        scrollFrame.content.PlayedTexts = scrollFrame.content.PlayedTexts or {}
        scrollFrame.content.LastPlayed = scrollFrame.content.LastPlayed or {}
        scrollFrame.content.HonourTexts = scrollFrame.content.HonourTexts or {}
        scrollFrame.content.BoonedTexts = scrollFrame.content.BoonedTexts or {}
        for _, name in ipairs(characters) do
            local char = AltwrightDB.global.characters[name]
            local charSyndicator = Syndicator.API.GetByCharacterFullName(name)
            if charSyndicator then
            local i = totalCharacters + 1 -- row index, skipped characters must not leave gaps
            AltwrightNS:CreateCharacterName(scrollFrame.content, i, char, scrollFrame.content, _PADDING, _HEIGHT, _ICON_SIZE)

            scrollFrame.content.MailTexts[i] = scrollFrame.content.MailTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.MailTexts[i]:Show()
            scrollFrame.content.MailTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 165, 0)
            local charMails = 0
            local charMailsInTransit = {}
            local charMailsExpiring = {}
            local charMailsColor = "GREEN_FONT_COLOR"
            char.Mail = char.Mail or {}
            for i=#char.Mail,1,-1 do
                if char.Mail[i].ArrivalTime < time() then
                    charMails = charMails + 1
                    local timeLeft = char.Mail[i].ExpiryTime - time()
                    local expiryLevel = timeLeft > 0 and AltwrightNS.AltwrightData:GetMailExpiryLevel(timeLeft)
                    if expiryLevel then
                        table.insert(charMailsExpiring, { ExpiryTime = char.Mail[i].ExpiryTime, Level = expiryLevel })
                        if expiryLevel == "urgent" then
                            charMailsColor = "RED_FONT_COLOR"
                        elseif charMailsColor ~= "RED_FONT_COLOR" then
                            charMailsColor = "YELLOW_FONT_COLOR"
                        end
                    end
                else
                    table.insert(charMailsInTransit, char.Mail[i].ArrivalTime)
                end
            end
            table.sort(charMailsExpiring, function(a, b) return a.ExpiryTime < b.ExpiryTime end)
            totalMail = totalMail + charMails + #charMailsInTransit
            if charMails>0 or #charMailsInTransit>0 then
                scrollFrame.content.MailTexts[i]:SetText("\124cn" .. charMailsColor .. ":" .. charMails .. "\124r (\124cnYELLOW_FONT_COLOR:" .. #charMailsInTransit .. "\124r)")
                if #charMailsInTransit>0 or #charMailsExpiring>0 then
                    scrollFrame.content.MailTexts[i]:SetScript("OnEnter", function(self)
                        AltwrightNS.AltwrightTooltip:SetOwner(self, "ANCHOR_CURSOR")
                        AltwrightNS.AltwrightTooltip:SetText(L["Mail"])
                        if #charMailsExpiring>0 then
                            AltwrightNS.AltwrightTooltip:AddLine(L["MailExpiringSoon"])
                            for _, mail in ipairs(charMailsExpiring) do
                                if mail.ExpiryTime > time() then
                                    local color = mail.Level == "urgent" and RED_FONT_COLOR or YELLOW_FONT_COLOR
                                    AltwrightNS.AltwrightTooltip:AddLine(L["MailExpiresIn"] .. " " .. AltwrightNS:LongTimeSpanToString(mail.ExpiryTime - time()), color.r, color.g, color.b)
                                end
                            end
                        end
                        if #charMailsInTransit>0 then
                            AltwrightNS.AltwrightTooltip:AddLine(L["MailInTransit"])
                            for _, arrivalTime in ipairs(charMailsInTransit) do
                                -- mail may have arrived since the frame was drawn, a negative span would show as ~24h
                                if arrivalTime > time() then
                                    AltwrightNS.AltwrightTooltip:AddLine(L["MailInTransit_ArrivesIn"] .. " " .. AltwrightNS:LongTimeSpanToString(arrivalTime - time()), 1, 1, 1)
                                end
                            end
                        end
                        AltwrightNS.AltwrightTooltip:Show()
                    end)
                    scrollFrame.content.MailTexts[i]:SetScript("OnLeave", function(self)
                        AltwrightNS.AltwrightTooltip:Hide()
                    end)
                else
                    scrollFrame.content.MailTexts[i]:SetScript("OnEnter", nil)
                    scrollFrame.content.MailTexts[i]:SetScript("OnLeave", nil)
                end
            else
                scrollFrame.content.MailTexts[i]:SetText(charMails)
                scrollFrame.content.MailTexts[i]:SetScript("OnEnter", nil)
                scrollFrame.content.MailTexts[i]:SetScript("OnLeave", nil)
            end

            local auctionCount = 0
            local auctionItems = 0
            for j, auction in pairs(charSyndicator["auctions"]) do
                if auction["itemCount"]>0 then
                    auctionCount = auctionCount + 1
                    auctionItems = auctionItems + auction["itemCount"]
                end
            end
            totalAuctions = totalAuctions + auctionCount
            totalAuctionItems = totalAuctionItems + auctionItems

            scrollFrame.content.AuctionTexts[i] = scrollFrame.content.AuctionTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.AuctionTexts[i]:Show()
            scrollFrame.content.AuctionTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 265, 0)
            if auctionCount>0 then
                scrollFrame.content.AuctionTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")\124r")
            else
                scrollFrame.content.AuctionTexts[i]:SetText(auctionCount .. " (" .. auctionItems .. " " .. L["AuctionItems"] .. ")")
            end
            

            scrollFrame.content.PlayedTexts[i] = scrollFrame.content.PlayedTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.PlayedTexts[i]:Show()
            scrollFrame.content.PlayedTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 390, 0)
            scrollFrame.content.PlayedTexts[i]:SetText(char.TimePlayed and AltwrightNS:LongTimeSpanToString(char.TimePlayed.Total) or "")
            totalPlayed = totalPlayed + (char.TimePlayed and char.TimePlayed.Total or 0)

            local lastPlayed = (char.LastLogout or char.LastLogin)
            scrollFrame.content.LastPlayed[i] = scrollFrame.content.LastPlayed[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.LastPlayed[i]:Show()
            scrollFrame.content.LastPlayed[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 515, 0)
            if name == data.FullName then
                scrollFrame.content.LastPlayed[i]:SetText("\124cnGREEN_FONT_COLOR:" .. L["Online"] .. "\124r")
            else
                scrollFrame.content.LastPlayed[i]:SetText(AltwrightNS:ShortTimeSpanToString(currentTime - lastPlayed))
            end
            local isOnline = name == data.FullName
            scrollFrame.content.LastPlayed[i]:SetScript("OnEnter", function(self)
                AltwrightNS.AltwrightTooltip:SetOwner(self, "ANCHOR_CURSOR")
                AltwrightNS.AltwrightTooltip:SetText(isOnline and L["Online"] or L["LastLogout"])
                local resting = L["NoData"]
                if char.Resting ~= nil then
                    resting = char.Resting and ("\124cnGREEN_FONT_COLOR:" .. L["Yes"] .. "\124r") or L["No"]
                end
                AltwrightNS.AltwrightTooltip:AddDoubleLine(L["Resting"], resting, 1, 1, 1, 1, 1, 1)
                local location = L["NoData"]
                if char.Location and char.Location.Zone then
                    location = char.Location.Zone
                    if char.Location.SubZone and char.Location.SubZone ~= "" and char.Location.SubZone ~= char.Location.Zone then
                        location = char.Location.SubZone .. ", " .. char.Location.Zone
                    end
                end
                AltwrightNS.AltwrightTooltip:AddDoubleLine(L["Location"], location, 1, 1, 1, 1, 1, 1)
                AltwrightNS.AltwrightTooltip:Show()
            end)
            scrollFrame.content.LastPlayed[i]:SetScript("OnLeave", function(self)
                AltwrightNS.AltwrightTooltip:Hide()
            end)

            scrollFrame.content.BoonedTexts[i] = scrollFrame.content.BoonedTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.BoonedTexts[i]:Show()
            scrollFrame.content.BoonedTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 640, 0)
            if char.WorldBuffs and #char.WorldBuffs > 0 then
                scrollFrame.content.BoonedTexts[i]:SetText("\124cnGREEN_FONT_COLOR:" .. #char.WorldBuffs .. "\124r")
                scrollFrame.content.BoonedTexts[i]:SetScript("OnEnter", function(self)
                    AltwrightNS.AltwrightTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    AltwrightNS.AltwrightTooltip:SetText(L["BoonedBuffs"])
                    AltwrightNS.AltwrightTooltip:AddLine(" ")
                    for _, buff in ipairs(char.WorldBuffs) do
                        AltwrightNS.AltwrightTooltip:AddDoubleLine(L["WorldBuffs"][buff.SpellId].name, AltwrightNS:LongTimeSpanToString(buff.ExpirationTime), 1, 1, 1)
                    end
                    AltwrightNS.AltwrightTooltip:Show()
                end)
                scrollFrame.content.BoonedTexts[i]:SetScript("OnLeave", function(self)
                    AltwrightNS.AltwrightTooltip:Hide()
                end)
            else
                scrollFrame.content.BoonedTexts[i]:SetText(L["No"])
                scrollFrame.content.BoonedTexts[i]:SetScript("OnEnter", nil)
                scrollFrame.content.BoonedTexts[i]:SetScript("OnLeave", nil)
            end
            

            scrollFrame.content.HonourTexts[i] = scrollFrame.content.HonourTexts[i] or scrollFrame.content:CreateFontString(nil,"ARTWORK","GameFontHighlight")
            scrollFrame.content.HonourTexts[i]:Show()
            scrollFrame.content.HonourTexts[i]:SetPoint("LEFT", scrollFrame.content.FactionIcons[i], "LEFT", 765, 0)
            char.Honour = char.Honour or { HKs = 0, Points = 0 }
            
            if AltwrightNS:GetLastReset() > lastPlayed then
                char.Honour.HKs = 0
                char.Honour.Points = 0
            end

            if char.Honour.HKs>=15 then
                scrollFrame.content.HonourTexts[i]:SetText(char.Honour.Points .. " (\124cnGREEN_FONT_COLOR:" .. char.Honour.HKs .. "\124r " .. L["Kills"] .. ")")
            else
                scrollFrame.content.HonourTexts[i]:SetText(L["HonourNotEnoughKills"] .. " (" .. char.Honour.HKs .. "/15)")
            end

            totalCharacters = totalCharacters + 1
            end
        end

        scrollFrame.content.TotalName = scrollFrame.content.TotalName or scrollFrame.content:CreateFontString("TotalsName", "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalName:Show()
        scrollFrame.content.TotalName:SetPoint("TOPLEFT", self.NameHeader, "BOTTOMLEFT", 0, _HEIGHT * -1 * (totalCharacters+2))
        scrollFrame.content.TotalName:SetText(L["Totals"])

        scrollFrame.content.TotalMailString = scrollFrame.content.TotalMailString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalMailString:Show()
        scrollFrame.content.TotalMailString:SetPoint("LEFT", scrollFrame.content.TotalName, "LEFT", 165, 0)
        scrollFrame.content.TotalMailString:SetText(totalMail)

        scrollFrame.content.TotalAuctionsString = scrollFrame.content.TotalAuctionsString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalAuctionsString:Show()
        scrollFrame.content.TotalAuctionsString:SetPoint("LEFT", scrollFrame.content.TotalName, "LEFT", 265, 0)
        scrollFrame.content.TotalAuctionsString:SetText(totalAuctions .. " (" .. totalAuctionItems .. " " .. L["AuctionItems"] .. ")")

        scrollFrame.content.TotalPlayedString = scrollFrame.content.TotalPlayedString or scrollFrame.content:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        scrollFrame.content.TotalPlayedString:Show()
        scrollFrame.content.TotalPlayedString:SetPoint("LEFT", scrollFrame.content.TotalName, "LEFT", 390, 0)
        scrollFrame.content.TotalPlayedString:SetText(AltwrightNS:LongTimeSpanToString(totalPlayed))
        scrollFrame.content:SetSize(C["Width"], _HEIGHT * (totalCharacters + 2))
    else
        self.NoDataFrame = self.NoDataFrame or self:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        self.NoDataFrame:SetPoint("CENTER", 0, 0)
        self.NoDataFrame:SetText(L["Syndicator_Not_Ready"])

        self:SetSize(C["Width"]-42, C["Height"] -50)
    end
end