-- RaidCaller.lua
-- Main addon object. Bulletproof Initialization for maximum stability.

RaidCaller = RaidCaller or {}

local addonName = "RaidCaller"
local RC = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
RaidCaller.addon = RC

-- This function is now called IMMEDIATELY when the addon is initialized
-- It now uses protected calls to prevent crashes from broken libraries.
function RC:OnInitialize()
    self:Print("RaidCaller v4.3 Initializing...")
    local ok

    -- 1. Safely initialize the database
    ok = pcall(function()
        local defaults = { profile = { isAutomatic = false, manualRaid = nil, manualBoss = nil, minimap = { hide = false } } }
        self.db = LibStub("AceDB-3.0"):New("RaidCallerDB", defaults, true)
    end)
    if not ok or not self.db then
        self:Print("|cffff0000CRITICAL ERROR: Failed to initialize AceDB-3.0. Addon will not function. Check your libraries.|r")
        return -- Halt initialization if DB fails, as nothing else will work.
    end

    -- 2. Safely create each module instance
    ok = pcall(function() self.Config = RaidCaller.ConfigModule:new(self.db) end)
    if not ok or not self.Config then self:Print("|cffff0000ERROR: Failed to create Config module.|r") end

    ok = pcall(function() self.BossDetector = RaidCaller.BossDetectorModule:new(self) end)
    if not ok or not self.BossDetector then self:Print("|cffff0000ERROR: Failed to create BossDetector module.|r") end

    ok = pcall(function() self.UI = RaidCaller.UIModule:new(self, self.Config) end)
    if not ok or not self.UI then self:Print("|cffff0000ERROR: Failed to create UI module. Commands and UI will be disabled. Your AceGUI-3.0 is likely broken.|r") end

    -- 3. Load phrase data
    self.phrases = RaidCaller.PhraseData or {}
    RaidCaller.PhraseData = nil -- Clean up global

    -- 4. Set up slash commands
    self:RegisterChatCommand("rc", "ChatCommand")
    self:RegisterChatCommand("raidcaller", "ChatCommand")
    
    self:Print("RaidCaller Initialization Complete. Check for errors above.")
end

-- This function is called AFTER OnInitialize, and is the safe place to register events
function RC:OnEnable()
    self:SetupMinimapIcon()
    
    -- Only register events if the required modules loaded correctly
    if self.BossDetector then
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    end
    
    if self.Config and self.Config:IsAutomaticMode() and IsAddOnLoaded("BigWigs") then
        self:HookBigWigs()
    end
end

-- We now have a dedicated function to hook BigWigs
function RC:HookBigWigs()
    if not self.BossDetector then return end -- Safety check
    self:RegisterMessage("BigWigs_EncounterStart", "OnEncounterStart")
    self:RegisterMessage("BigWigs_EncounterEnd", "OnEncounterEnd")
    self:Print("BigWigs integration enabled for Automatic Mode.")
end

function RC:UnhookBigWigs()
    self:UnregisterMessage("BigWigs_EncounterStart")
    self:UnregisterMessage("BigWigs_EncounterEnd")
    self:Print("BigWigs integration disabled.")
end

-- Slash command handler (made hyper-robust)
function RC:ChatCommand(input)
    -- Check if the UI module loaded correctly before attempting to use it
    if not self.UI then
        self:Print("The UI module failed to load due to an error. Please check your libraries, especially AceGUI-3.0.")
        return
    end

    if type(input) ~= "string" then return end 

    if input == "" then
        -- Safely toggle UI
        if self.UI.Toggle then self.UI:Toggle() end
        return
    end
    
    local ok, command, arg = pcall(string.match, input, "^(%S+)%s*(.-)$")
    if not ok or not command then return end

    command = string.lower(command)

    if command == "say" and tonumber(arg) then
        self:SayPhrase(tonumber(arg))
    elseif command == "toggle" then
        if self.UI.Toggle then self.UI:Toggle() end
    else
        self:Print("Usage: /rc [toggle|say <#>]")
    end
end

-- Setup the minimap icon (with better logging)
function RC:SetupMinimapIcon()
    local LDB = LibStub("LibDBIcon-1.0", true)
    if not LDB then
        self:Print("|cffff8800Warning: LibDBIcon-1.0 library not found or failed to load. Minimap icon disabled.|r")
        return
    end

    LDB:Register("RaidCaller", {
        icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
        tooltip = "RaidCaller",
        onclick = function(_, button)
            if button == "LeftButton" then
                -- Safely toggle UI from icon
                if self.UI and self.UI.Toggle then self.UI:Toggle() end
            end
        end
    }, self.db.profile.minimap)
end

-- Event handlers (with safety checks)
function RC:PLAYER_ENTERING_WORLD() if self.BossDetector then self.BossDetector:UpdateZone() end end
function RC:ZONE_CHANGED_NEW_AREA() if self.BossDetector then self.BossDetector:UpdateZone() end end
function RC:OnEncounterStart(_, _, _, _, bossName) if self.BossDetector then self.BossDetector:SetBoss(bossName) end end
function RC:OnEncounterEnd() if self.BossDetector then self.BossDetector:SetBoss(nil) end end

-- Core functionality
function RC:GetCurrentPhrases()
    if not self.BossDetector then return nil end -- Safety check
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
