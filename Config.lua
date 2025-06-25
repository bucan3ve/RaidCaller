-- Config.lua
-- Manages addon settings and data persistence using AceDB-3.0

RaidCaller = RaidCaller or {}

local ConfigModule = {}
RaidCaller.ConfigModule = ConfigModule

function ConfigModule:new(db)
    local config = {}
    config.db = db

    -- Set the mode (auto/manual)
    function config:SetAutomaticMode(isAutomatic)
        self.db.profile.isAutomatic = isAutomatic
    end

    -- Get the current mode
    function config:IsAutomaticMode()
        return self.db.profile.isAutomatic
    end

    -- Set the manually selected raid
    function config:SetManualRaid(raid)
        self.db.profile.manualRaid = raid
    end

    -- Get the manually selected raid
    function config:GetManualRaid()
        return self.db.profile.manualRaid
    end

    -- Set the manually selected boss
    function config:SetManualBoss(boss)
        self.db.profile.manualBoss = boss
    end

    -- Get the manually selected boss
    function config:GetManualBoss()
        return self.db.profile.manualBoss
    end

    return config
end
