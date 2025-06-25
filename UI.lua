-- UI.lua
-- Creates and manages the user interface for RaidCaller

RaidCaller = RaidCaller or {}

local UIModule = {}
RaidCaller.UIModule = UIModule

local AceGUI = LibStub("AceGUI-3.0")
local MAX_BUTTONS = 15

-- Helper function to safely create widgets and report errors
local function CreateWidget(widgetType)
    local widget = AceGUI:Create(widgetType)
    if not widget then
        print(string.format("|cffff0000RaidCaller Error: AceGUI failed to create a '%s'. Your AceGUI-3.0 library is likely incomplete or corrupted.|r", widgetType))
    end
    return widget
end

function UIModule:new(addon)
    local ui = {}
    setmetatable(ui, { __index = self })
    
    ui.addon = addon
    ui.config = addon.Config
    ui.mainFrame = nil
    ui.widgets = {}
    ui.sortedRaidNames = {} 
    ui.sortedBossNames = {}

    return ui
end

function UIModule:Create()
    self.mainFrame = CreateWidget("Frame")
    if not self.mainFrame then return end

    self.mainFrame:SetTitle("RaidCaller v5.2")
    self.mainFrame:SetLayout("Flow")
    self.mainFrame:SetPoint("CENTER")
    self.mainFrame:SetWidth(400)
    self.mainFrame:SetHeight(500)
    self.mainFrame:Hide()

    local controlsGroup = CreateWidget("SimpleGroup")
    if controlsGroup then
        controlsGroup:SetLayout("Flow")
        controlsGroup:SetFullWidth(true)
        self.mainFrame:AddChild(controlsGroup)

        self.widgets.autoModeCheckbox = CreateWidget("CheckBox")
        if self.widgets.autoModeCheckbox then
            self.widgets.autoModeCheckbox:SetLabel("Automatic Mode (requires BigWigs)")
            self.widgets.autoModeCheckbox:SetValue(self.config:IsAutomaticMode())
            self.widgets.autoModeCheckbox:SetCallback("OnValueChanged", function()
                local currentState = self.config:IsAutomaticMode()
                local newState = not currentState
                self.config:SetAutomaticMode(newState)
                if newState then self.addon:HookBigWigs() else self.addon:UnhookBigWigs() end
                self:Update()
            end)
            controlsGroup:AddChild(self.widgets.autoModeCheckbox)
        end

        -- Raid Dropdown -- FIXED
        self.widgets.raidDropdown = CreateWidget("Dropdown")
        if self.widgets.raidDropdown then
            self.widgets.raidDropdown:SetLabel("Select Raid")
            -- CORRECTED: The callback signature now correctly captures the 4th argument as the value.
            self.widgets.raidDropdown:SetCallback("OnValueChanged", function(_, _, _, selectedRaidName)
                self.addon:DebugPrint("Raid dropdown callback fired! Value:", selectedRaidName or "nil")
                if selectedRaidName then
                    self.config:SetManualRaid(selectedRaidName)
                    self.config:SetManualBoss(nil) -- Reset boss selection when raid changes
                    self:Update()
                end
            end)
            controlsGroup:AddChild(self.widgets.raidDropdown)
        end

        -- Boss Dropdown -- FIXED
        self.widgets.bossDropdown = CreateWidget("Dropdown")
        if self.widgets.bossDropdown then
            self.widgets.bossDropdown:SetLabel("Select Boss")
            -- CORRECTED: The callback signature now correctly captures the 4th argument as the value.
            self.widgets.bossDropdown:SetCallback("OnValueChanged", function(_, _, _, selectedBossName)
                self.addon:DebugPrint("Boss dropdown callback fired! Value:", selectedBossName or "nil")
                if selectedBossName then
                    self.config:SetManualBoss(selectedBossName)
                    self:Update()
                end
            end)
            controlsGroup:AddChild(self.widgets.bossDropdown)
        end
    end

    local spacer = CreateWidget("Label")
    if spacer then
        spacer:SetText("----------------------------------------")
        spacer:SetFullWidth(true)
        self.mainFrame:AddChild(spacer)
    end

    local phraseGroup = CreateWidget("ScrollFrame")
    if phraseGroup then
        phraseGroup:SetLayout("Flow")
        phraseGroup:SetFullWidth(true)
        phraseGroup:SetHeight(300)
        self.mainFrame:AddChild(phraseGroup)
        self.widgets.phraseGroup = phraseGroup
        self.widgets.phraseButtons = {}
    end
    
    return self.mainFrame
end

function UIModule:Update()
    self.addon:Print("|cffffff00UI:Update() triggered.|r")

    if not self.mainFrame then return end
    
    local isAutomatic = self.config:IsAutomaticMode()
    if self.widgets.autoModeCheckbox then self.widgets.autoModeCheckbox:SetValue(isAutomatic) end
    if self.widgets.raidDropdown then self.widgets.raidDropdown:SetDisabled(isAutomatic) end
    if self.widgets.bossDropdown then self.widgets.bossDropdown:SetDisabled(isAutomatic) end

    -- ======== RAID LIST LOGIC ========
    if self.widgets.raidDropdown then
        self.sortedRaidNames = {}
        for raidName in pairs(self.addon.phrases) do 
            table.insert(self.sortedRaidNames, raidName) 
        end
        table.sort(self.sortedRaidNames)
        
        local raidList = {}
        for _, raidName in ipairs(self.sortedRaidNames) do
            raidList[raidName] = raidName
        end
        
        self.widgets.raidDropdown:SetList(raidList, self.sortedRaidNames)
        self.widgets.raidDropdown:SetValue(self.config:GetManualRaid())
    end

    -- ======== BOSS LIST LOGIC ========
    if self.widgets.bossDropdown then
        self.sortedBossNames = {}
        
        local currentRaid = nil
        if isAutomatic then
            currentRaid = self.addon.BossDetector.currentZone
        else
            currentRaid = self.config:GetManualRaid()
        end
        
        if currentRaid and self.addon.phrases[currentRaid] then
            for bossName in pairs(self.addon.phrases[currentRaid]) do
                table.insert(self.sortedBossNames, bossName)
            end
            table.sort(self.sortedBossNames)
            
            local bossList = {}
            for _, bossName in ipairs(self.sortedBossNames) do
                bossList[bossName] = bossName
            end
            
            self.widgets.bossDropdown:SetList(bossList, self.sortedBossNames)
            
            if isAutomatic then
                self.widgets.bossDropdown:SetValue(self.addon.BossDetector.currentBoss)
            else
                self.widgets.bossDropdown:SetValue(self.config:GetManualBoss())
            end
        else
            self.widgets.bossDropdown:SetList({})
            self.widgets.bossDropdown:SetValue(nil)
        end
    end
    
    -- ======== PHRASE BUTTONS LOGIC ========
    if self.widgets.phraseGroup then
        self.widgets.phraseGroup:ReleaseChildren()
        self.widgets.phraseButtons = {}
        
        local phrases = self.addon:GetCurrentPhrases()
        
        if phrases then
            for i, phrase in ipairs(phrases) do
                if i <= MAX_BUTTONS then
                    local btn = CreateWidget("Button")
                    if btn then
                        btn:SetText(i .. ". " .. phrase)
                        btn:SetFullWidth(true)
                        btn.phraseIndex = i
                        btn:SetCallback("OnClick", function(widget)
                            self.addon:SayPhrase(widget.phraseIndex)
                        end)
                        self.widgets.phraseGroup:AddChild(btn)
                        table.insert(self.widgets.phraseButtons, btn)
                    end
                end
            end
        end
    end
end

function UIModule:Toggle()
    if not self.mainFrame then self:Create() end
    if not self.mainFrame then return end
    
    if self.mainFrame.frame:IsShown() then
        self.mainFrame:Hide()
    else
        self:Update()
        self.mainFrame:Show()
    end
end