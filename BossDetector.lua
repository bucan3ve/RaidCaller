-- BossDetector.lua
-- Handles detection of the current zone and boss.

RaidCaller = RaidCaller or {}

local BossDetectorModule = {}
RaidCaller.BossDetectorModule = BossDetectorModule

function BossDetectorModule:new(addon)
    local detector = {}
    detector.addon = addon
    detector.currentZone = nil
    detector.currentBoss = nil -- This is only used for Automatic mode

    -- Update the current zone text (for automatic mode)
    function detector:UpdateZone()
        if not self.addon.Config:IsAutomaticMode() then return end
        self.currentZone = GetZoneText()
        self.currentBoss = nil -- Reset boss when zone changes
        self.addon.UI:Update()
    end

    -- Set the current boss from BigWigs (for automatic mode)
    function detector:SetBoss(bossName)
        if not self.addon.Config:IsAutomaticMode() then return end
        self.currentBoss = bossName
        self.addon:Print("Encounter Detected (Auto Mode): " .. tostring(bossName or "None"))
        self.addon.UI:Update()
    end
    
    -- Returns the currently active raid and boss based on the addon's mode
    function detector:GetCurrentRaidAndBoss()
        if self.addon.Config:IsAutomaticMode() then
            -- In auto mode, we use the detected zone and boss
            return self.currentZone, self.currentBoss
        else
            -- In manual mode, we use the values saved in our config
            return self.addon.Config:GetManualRaid(), self.addon.Config:GetManualBoss()
        end
    end

    return detector
end
