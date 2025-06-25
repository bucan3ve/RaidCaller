-- RaidCaller.lua
-- Main addon object. Restored to original, stable structure.

RaidCaller = RaidCaller or {}

local addonName = "RaidCaller"
local RC = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
RaidCaller.addon = RC

RC.debug = false

-- FIXED: Simplified the debug function to be more reliable.
function RC:DebugPrint(message)
    if not self.debug then return end
    self:Print("|cff33ff99DEBUG:|r " .. tostring(message))
end


-- Initialize modules
function RC:OnInitialize()
    self:Print("RaidCaller Initializing...")
    
    -- Database
    local defaults = {
        profile = {
            isAutomatic = false,
            manualRaid = nil,
            manualBoss = nil,
            minimap = {
                hide = false,
            }
        }
    }
    self.db = LibStub("AceDB-3.0"):New("RaidCallerDB", defaults, true)

    -- Modules
    self.phrases = RaidCaller.PhraseData or {}
    RaidCaller.PhraseData = nil -- Clear global reference

    self.Config = RaidCaller.ConfigModule:new(self.db)
    self.BossDetector = RaidCaller.BossDetectorModule:new(self)
    self.UI = RaidCaller.UIModule:new(self)
    
    -- Slash commands
    self:RegisterChatCommand("rc", "ChatCommand")
    self:RegisterChatCommand("raidcaller", "ChatCommand")
    
    self:Print("RaidCaller Initialized.")
end

function RC:OnEnable()
    self:Print("RaidCaller Enabled.")
    
    -- Register for events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    if self.Config:IsAutomaticMode() and IsAddOnLoaded("BigWigs") then
        self:HookBigWigs()
    end

    -- Setup minimap icon
    self:SetupMinimapIcon()
end

function RC:HookBigWigs()
    if not self.BossDetector then return end
    self:RegisterMessage("BigWigs_EncounterStart", "OnEncounterStart")
    self:RegisterMessage("BigWigs_EncounterEnd", "OnEncounterEnd")
    self:Print("BigWigs integration enabled for Automatic Mode.")
end

function RC:UnhookBigWigs()
    self:UnregisterMessage("BigWigs_EncounterStart")
    self:UnregisterMessage("BigWigs_EncounterEnd")
    self:Print("BigWigs integration disabled.")
end

function RC:ChatCommand(input)
    if not self.UI then return end
    if type(input) ~= "string" then return end

    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    if input == "" then
        self.UI:Toggle()
        return
    end
    
    local command, argStr = string.match(input, "^(%S+)%s*(.*)$")
    if not command then
        command = input
        argStr = ""
    end

    command = string.lower(command)

    if command == "say" and tonumber(argStr) then
        self:SayPhrase(tonumber(argStr))
    elseif command == "toggle" then
        self.UI:Toggle()
    elseif command == "debug" then
        self.debug = not self.debug
        self:Print("Debug mode is now: " .. (self.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        self:Print("Usage: /rc [toggle|debug|say <#>]")
    end
end


function RC:SetupMinimapIcon()
    local LDB = LibStub("LibDBIcon-1.0", true)
    if not LDB then
        self:Print("|cffff8800Warning: LibDBIcon-1.0 library not found. Minimap icon disabled.|r")
        return
    end
    
    local uiObject = self.UI
    if not uiObject then
        self:Print("|cffff0000Error: UI object not found when setting up minimap icon.|r")
        return
    end

    LDB:Register("RaidCaller", {
        icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
        tooltip = "RaidCaller",
        onclick = function(_, button)
            if button == "LeftButton" then
                uiObject:Toggle()
            end
        end
    }, self.db.profile.minimap)
end

function RC:PLAYER_ENTERING_WORLD() if self.BossDetector then self.BossDetector:UpdateZone() end end
function RC:ZONE_CHANGED_NEW_AREA() if self.BossDetector then self.BossDetector:UpdateZone() end end
function RC:OnEncounterStart(_, _, _, _, bossName) if self.BossDetector then self.BossDetector:SetBoss(bossName) end end
function RC:OnEncounterEnd() if self.BossDetector then self.BossDetector:SetBoss(nil) end end

function RC:GetCurrentPhrases()
    if not self.BossDetector then return nil end
    local currentRaid, currentBoss = self.BossDetector:GetCurrentRaidAndBoss()
    
    self:DebugPrint("GetCurrentPhrases - Raid: " .. tostring(currentRaid or "nil") .. " Boss: " .. tostring(currentBoss or "nil"))

    if currentRaid and currentBoss and self.phrases[currentRaid] and self.phrases[currentRaid][currentBoss] then
        return self.phrases[currentRaid][currentBoss].Phrases
    end
    return nil
end

function RC:SayPhrase(index)
    local phrases = self:GetCurrentPhrases()
    if not phrases or not phrases[index] then
        self:Print("No phrase found. Please select a raid and boss in manual mode.")
        return
    end
    
    self:DebugPrint("Saying phrase " .. tostring(index) .. ": " .. tostring(phrases[index]))

    -- FIXED: Corrected the typo from 'UnitlsGroupAssistant' to the correct 'UnitIsGroupAssistant'
    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        SendChatMessage(phrases[index], "RAID")
    else
        self:Print("You must be a raid leader or assistant to make calls.")
    end
end

-- Global function for the toggle keybind.
function RaidCaller_Toggle()
    if RaidCaller and RaidCaller.addon and RaidCaller.addon.UI then
        RaidCaller.addon.UI:Toggle()
    end
end

-- Global function for the "say" keybinds.
function RaidCaller_Say(index)
    if RaidCaller and RaidCaller.addon then
        RaidCaller.addon:SayPhrase(index)
    end
end