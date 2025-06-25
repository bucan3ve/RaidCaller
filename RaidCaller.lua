-- RaidCaller.lua
-- Main addon object. Refactored for two-window UI and LDB support.

RaidCaller = RaidCaller or {}

local addonName = "RaidCaller"
local RC = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0")
RaidCaller.addon = RC

RC.debug = false
RC.ldb = nil -- Placeholder for our LDB object

function RC:DebugPrint(message)
    if not self.debug then return end
    self:Print("|cff33ff99DEBUG:|r " .. tostring(message))
end


-- Initialize modules
function RC:OnInitialize()
    self:Print("RaidCaller Initializing...")
    
    local defaults = {
        profile = {
            isAutomatic = false,
            manualRaid = nil,
            manualBoss = nil,
            sendAsWarning = false,
            minimap = {
                hide = false,
            }
        }
    }
    self.db = LibStub("AceDB-3.0"):New("RaidCallerDB", defaults, true)

    self.phrases = RaidCaller.PhraseData or {}
    RaidCaller.PhraseData = nil 

    self.Config = RaidCaller.ConfigModule:new(self.db)
    self.BossDetector = RaidCaller.BossDetectorModule:new(self)
    self.UI = RaidCaller.UIModule:new(self)
    
    self:RegisterChatCommand("rc", "ChatCommand")
    self:RegisterChatCommand("raidcaller", "ChatCommand")
    
    self:Print("RaidCaller Initialized.")
end

function RC:OnEnable()
    self:Print("RaidCaller Enabled.")
    
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateLDBText")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    
    if self.Config:IsAutomaticMode() and IsAddOnLoaded("BigWigs") then
        self:HookBigWigs()
    end

    self:SetupLDB()
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
        self.UI:ToggleSettings()
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
    elseif command == "toggle" or command == "settings" then
        self.UI:ToggleSettings()
    elseif command == "phrases" then
        self.UI:TogglePhrases()
    elseif command == "debug" then
        self.debug = not self.debug
        self:Print("Debug mode is now: " .. (self.debug and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
    else
        self:Print("Usage: /rc [settings|phrases|debug|say <#>]")
    end
end

function RC:UpdateLDBText()
    if not self.ldb then return end

    local text
    if self.Config:IsAutomaticMode() then
        local _, boss = self.BossDetector:GetCurrentRaidAndBoss()
        if boss then
            text = "RaidCaller: " .. boss
        else
            text = "RaidCaller (Auto)"
        end
    else
        local _, boss = self.BossDetector:GetCurrentRaidAndBoss()
        if boss then
            text = "RaidCaller: " .. boss
        else
            text = "RaidCaller (Manual)"
        end
    end
    self.ldb.text = text
end

function RC:SetupLDB()
    local LDB = LibStub("LibDataBroker-1.1", true)
    local LDBIcon = LibStub("LibDBIcon-1.0", true)

    if not LDB or not LDBIcon then
        self:Print("|cffff8800Warning: LDB or LDBIcon library not found. Minimap icon disabled.|r")
        return
    end

    self.ldb = LDB:NewDataObject("RaidCaller", {
        type = "launcher",
        label = "RaidCaller",
        icon = "Interface\\Icons\\Spell_Holy_WordFortitude",
        
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("RaidCaller")
            tooltip:AddLine("Left-click to toggle Settings.")
            tooltip:AddLine("Right-click for options.")
        end,

        OnClick = function(_, button)
            if button == "LeftButton" then
                self.UI:ToggleSettings()
            elseif button == "RightButton" then
                self:Print("Right-click options are configured in the main UI window (/rc).")
            end
        end
    })

    LDBIcon:Register("RaidCaller", self.ldb, self.db.profile.minimap)
    self:UpdateLDBText()
end

function RC:PLAYER_ENTERING_WORLD() if self.BossDetector then self.BossDetector:UpdateZone(); self:UpdateLDBText() end end
function RC:ZONE_CHANGED_NEW_AREA() if self.BossDetector then self.BossDetector:UpdateZone(); self:UpdateLDBText() end end
function RC:OnEncounterStart(_, _, _, _, bossName) if self.BossDetector then self.BossDetector:SetBoss(bossName); self:UpdateLDBText() end end
function RC:OnEncounterEnd() if self.BossDetector then self.BossDetector:SetBoss(nil); self:UpdateLDBText() end end

function RC:GetCurrentPhrases()
    if not self.BossDetector then return nil end
    local currentRaid, currentBoss = self.BossDetector:GetCurrentRaidAndBoss()
    
    self:DebugPrint("GetCurrentPhrases - Raid: " .. tostring(currentRaid or "nil") .. " Boss: " .. tostring(currentBoss or "nil"))

    if not currentRaid or not currentBoss then
        self:DebugPrint("Lookup failed: Raid or Boss is nil.")
        return nil
    end

    if not self.phrases[currentRaid] then
        self:DebugPrint("Lookup failed: Raid key '" .. tostring(currentRaid) .. "' not found in phrases table.")
        return nil
    end
    
    if not self.phrases[currentRaid][currentBoss] then
        self:DebugPrint("Lookup failed: Boss key '" .. tostring(currentBoss) .. "' not found in raid '" .. tostring(currentRaid) .. "'.")
        return nil
    end

    return self.phrases[currentRaid][currentBoss].Phrases
end


function RC:SayPhrase(index)
    local phrases = self:GetCurrentPhrases()
    if not phrases or not phrases[index] then
        self:Print("No phrase found. Please select a raid and boss in manual mode.")
        return
    end
    
    local channel = "RAID"
    if self.Config:IsSendAsWarning() then
        channel = "RAID_WARNING"
    end
    
    self:DebugPrint("Saying phrase " .. tostring(index) .. " to channel " .. channel .. ": " .. tostring(phrases[index]))

    if UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") then
        SendChatMessage(phrases[index], channel)
    else
        self:Print("You must be a raid leader or assistant to make calls.")
    end
end

function RaidCaller_Toggle()
    if RaidCaller and RaidCaller.addon and RaidCaller.addon.UI then
        RaidCaller.addon.UI:ToggleSettings()
    end
end

function RaidCaller_Say(index)
    if RaidCaller and RaidCaller.addon then
        RaidCaller.addon:SayPhrase(index)
    end
end