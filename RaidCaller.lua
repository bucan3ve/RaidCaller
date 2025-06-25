-- RaidCaller.lua
-- Main addon object. Refactored for stability with a "Manual First" approach.

RaidCaller = RaidCaller or {}

local addonName = "RaidCaller"
local RC = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
RaidCaller.addon = RC

function RC:OnInitialize()
    -- Initialize the database with new defaults
    local defaults = {
        profile = {
            isAutomatic = false, -- Default to MANUAL mode for stability
            manualRaid = nil,
            manualBoss = nil,
            minimap = { hide = false }
        }
    }
    self.db = LibStub("AceDB-3.0"):New("RaidCallerDB", defaults, true)
    
    -- Load the phrase table directly from phrases.lua
    self.phrases = RaidCaller.PhraseData or {}
    RaidCaller.PhraseData = nil -- Clean up global table to save memory
    
    self:SetupMinimapIcon()
    self:RegisterChatCommand("rc", "ChatCommand")
    self:RegisterChatCommand("raidcaller", "ChatCommand")
    
    self:Print("RaidCaller v4.0 Initialized. Defaulting to Manual Mode.")
end

function RC:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    -- We only hook BigWigs if the user has enabled automatic mode
    if self.Config and self.Config:IsAutomaticMode() and IsAddOnLoaded("BigWigs") then
        self:HookBigWigs()
    end
end

-- We now have a dedicated function to hook BigWigs
function RC:HookBigWigs()
    self:RegisterMessage("BigWigs_EncounterStart", "OnEncounterStart")
    self:RegisterMessage("BigWigs_EncounterEnd", "OnEncounterEnd")
    self:Print("BigWigs integration enabled for Automatic Mode.")
end

function RC:UnhookBigWigs()
    self:UnregisterMessage("BigWigs_EncounterStart")
    self:UnregisterMessage("BigWigs_EncounterEnd")
    self:Print("BigWigs integration disabled.")
end

-- Store references to the other modules
function RC:SetModules(Config, UI, BossDetector)
    self.Config = Config
    self.UI = UI
    self.BossDetector = BossDetector
end

-- Slash command handler
function RC:ChatCommand(input)
    if not input or input == "" then
        self.UI:Toggle()
        return
    end
    
    local command, arg = input:match("^(%S+)%s*(.-)$")
    command = command and string.lower(command)

    if command == "say" and tonumber(arg) then
        self:SayPhrase(tonumber(arg))
    elseif command == "toggle" then
        self.UI:Toggle()
    else
        self:Print("Usage: /rc [toggle|say <#>]")
    end
end

-- Setup the minimap icon (now with error checking)
function RC:SetupMinimapIcon()
    local LDB = LibStub("LibDBIcon-1.0", true) -- Use 'true' to prevent errors
    if not LDB then
        self:Print("Warning: LibDBIcon-1.0 not found. Minimap icon will be disabled.")
        return
    end

    LDB:Register("RaidCaller", {
        icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
        tooltip = "RaidCaller",
        onclick = function(_, button)
            if button == "LeftButton" then
                self.UI:Toggle()
            end
        end
    }, self.db.profile.minimap)
end

-- Event handlers (only act in automatic mode)
function RC:PLAYER_ENTERING_WORLD() self.BossDetector:UpdateZone() end
function RC:ZONE_CHANGED_NEW_AREA() self.BossDetector:UpdateZone() end
function RC:OnEncounterStart(_, _, _, _, bossName) self.BossDetector:SetBoss(bossName) end
function RC:OnEncounterEnd() self.BossDetector:SetBoss(nil) end

-- Core functionality
function RC:GetCurrentPhrases()
    local currentRaid, currentBoss = self.BossDetector:GetCurrentRaidAndBoss()
    
    if currentRaid and currentBoss and self.phrases[currentRaid] and self.phrases[currentRaid][currentBoss] then
        return self.phrases[currentRaid][currentBoss].Phrases
    end

    return nil -- Return nil if no valid phrases are found
end

function RC:SayPhrase(index)
    local phrases = self:GetCurrentPhrases()
    
    if not phrases or not phrases[index] then
        self:Print("No phrase found. Please select a raid and boss in manual mode.")
        return
    end

    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        SendChatMessage(phrases[index], "RAID")
    else
        self:Print("You must be a raid leader or assistant to make calls.")
    end
end
