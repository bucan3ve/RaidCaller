-- RaidCaller.lua
-- Main addon object. Rewritten with a stable, two-phase initialization lifecycle.

RaidCaller = RaidCaller or {}

local addonName = "RaidCaller"
local RC = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
RaidCaller.addon = RC


-- PHASE 1: Initialize non-UI, non-event systems. This runs very early.
function RC:OnInitialize()
    self:Print("RaidCaller Initializing (Phase 1: Core Systems)...")
    
    -- Setup Database
    local defaults = { profile = { isAutomatic = false, manualRaid = nil, manualBoss = nil, minimap = { hide = false } } }
    self.db = LibStub("AceDB-3.0"):New("RaidCallerDB", defaults, true)

    -- Create non-UI modules
    self.Config = RaidCaller.ConfigModule:new(self.db)
    self.BossDetector = RaidCaller.BossDetectorModule:new(self)

    -- Load phrase data
    self.phrases = RaidCaller.PhraseData or {}
    RaidCaller.PhraseData = nil -- Clear global reference after loading
    
    self:Print("Core Systems Initialized.")
end

-- PHASE 2: Initialize UI and connect to the game world. This runs when the addon is enabled.
function RC:OnEnable()
    self:Print("RaidCaller Enabling (Phase 2: UI and Events)...")

    -- Create the UI module HERE. It's safer as it may create frames.
    self.UI = RaidCaller.UIModule:new(self, self.Config)
    if not self.UI then
        self:Print("|cffff0000CRITICAL ERROR: UI Module failed to create. Addon will be non-interactive.|r")
        return
    end

    -- Setup slash commands HERE, now that we know the UI object exists.
    self:RegisterChatCommand("rc", "ChatCommand")
    self:RegisterChatCommand("raidcaller", "ChatCommand")

    -- Setup the minimap icon
    self:SetupMinimapIcon()
    
    -- Register for game events
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    -- Hook other addons if needed
    if self.Config and self.Config:IsAutomaticMode() and IsAddOnLoaded("BigWigs") then
        self:HookBigWigs()
    end

    self:Print("RaidCaller Fully Enabled and Ready.")
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
    if not self.UI then return end -- Safety check
    if type(input) ~= "string" then return end

    if input == "" then
        self.UI:Toggle()
        return
    end
    
    -- IMPROVEMENT: Use pcall to safely parse input. If it fails, default to toggling the UI.
    local ok, command, arg = pcall(string.match, input, "^(%S+)%s*(.-)$")
    if not ok or not command then
        self.UI:Toggle()
        return
    end

    command = string.lower(command)

    if command == "say" and tonumber(arg) then
        self:SayPhrase(tonumber(arg))
    elseif command == "toggle" then
        self.UI:Toggle()
    else
        self:Print("Usage: /rc [toggle|say <#>]")
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

    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        SendChatMessage(phrases[index], "RAID")
    else
        self:Print("You must be a raid leader or assistant to make calls.")
    end
end

--
-- !! GLOBAL FUNCTIONS FOR BINDINGS !!
--

-- Global function for the toggle keybind.
function RaidCaller_Toggle()
    -- Safely check if the addon and its UI have been loaded.
    if RaidCaller and RaidCaller.addon and RaidCaller.addon.UI then
        RaidCaller.addon.UI:Toggle()
    end
end

-- Global function for the "say" keybinds.
function RaidCaller_Say(index)
    -- Safely check if the addon has been loaded.
    if RaidCaller and RaidCaller.addon then
        RaidCaller.addon:SayPhrase(index)
    end
end