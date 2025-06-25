-- UI.lua
-- Creates and manages the user interface for RaidCaller. Now with two separate windows.

RaidCaller = RaidCaller or {}

local UIModule = {}
RaidCaller.UIModule = UIModule

local AceGUI = LibStub("AceGUI-3.0")
local MAX_BUTTONS = 15

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
    ui.settingsFrame = nil
    ui.phrasesFrame = nil
    ui.widgets = {
        settings = {},
        phrases = {}
    }
    ui.sortedRaidNames = {} 
    ui.sortedBossNames = {}

    return ui
end

-- ===================================================================
-- Window Creation Functions
-- ===================================================================

function UIModule:CreateSettingsFrame()
    local frame = CreateWidget("Frame")
    if not frame then return end
    
    frame:SetTitle("RaidCaller Settings")
    frame:SetLayout("Flow")
    frame:SetPoint("CENTER")
    frame:SetWidth(450)
    frame:SetHeight(230)
    frame.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)

    self.settingsFrame = frame
    local widgets = self.widgets.settings

    local controlsGroup = CreateWidget("SimpleGroup")
    controlsGroup:SetLayout("Flow")
    controlsGroup:SetFullWidth(true)
    frame:AddChild(controlsGroup)
    
    local togglesGroup = CreateWidget("SimpleGroup")
    togglesGroup:SetLayout("List")
    togglesGroup:SetWidth(200)
    controlsGroup:AddChild(togglesGroup)

    widgets.autoModeCheckbox = CreateWidget("CheckBox")
    togglesGroup:AddChild(widgets.autoModeCheckbox)
    widgets.autoModeCheckbox:SetLabel("Automatic Mode")
    widgets.autoModeCheckbox:SetCallback("OnValueChanged", function(_, _, _, value)
        self.config:SetAutomaticMode(value)
        if value then self.addon:HookBigWigs() else self.addon:UnhookBigWigs() end
        self:UpdateFrames()
    end)

    widgets.warningCheckbox = CreateWidget("CheckBox")
    togglesGroup:AddChild(widgets.warningCheckbox)
    widgets.warningCheckbox:SetLabel("Send as Raid Warning")
    widgets.warningCheckbox:SetCallback("OnValueChanged", function(_, _, _, value)
        self.config:SetSendAsWarning(value)
        self.addon:DebugPrint("Send as Raid Warning set to: " .. tostring(value))
    end)

    local selectsGroup = CreateWidget("SimpleGroup")
    selectsGroup:SetLayout("List")
    selectsGroup:SetWidth(200)
    controlsGroup:AddChild(selectsGroup)

    widgets.raidDropdown = CreateWidget("Dropdown")
    selectsGroup:AddChild(widgets.raidDropdown)
    widgets.raidDropdown:SetLabel("Select Raid")
    widgets.raidDropdown:SetCallback("OnValueChanged", function(_, _, _, selectedRaidName)
        self.addon:DebugPrint("Raid dropdown callback fired! Value: " .. tostring(selectedRaidName or "nil"))
        if selectedRaidName then
            self.config:SetManualRaid(selectedRaidName)
            self.config:SetManualBoss(nil) 
            self:UpdateFrames()
        end
    end)

    widgets.bossDropdown = CreateWidget("Dropdown")
    selectsGroup:AddChild(widgets.bossDropdown)
    widgets.bossDropdown:SetLabel("Select Boss")
    widgets.bossDropdown:SetCallback("OnValueChanged", function(_, _, _, selectedBossName)
        self.addon:DebugPrint("Boss dropdown callback fired! Value: " .. tostring(selectedBossName or "nil"))
        if selectedBossName then
            self.config:SetManualBoss(selectedBossName)
            self:UpdateFrames()
        end
    end)
    
    local footerGroup = CreateWidget("SimpleGroup")
    footerGroup:SetLayout("Flow")
    footerGroup:SetFullWidth(true)
    frame:AddChild(footerGroup)
    
    widgets.togglePhrasesButton = CreateWidget("Button")
    footerGroup:AddChild(widgets.togglePhrasesButton)
    widgets.togglePhrasesButton:SetText("Toggle Phrases")
    widgets.togglePhrasesButton:SetWidth(180) 
    widgets.togglePhrasesButton:SetCallback("OnClick", function() self:TogglePhrases() end)

    return frame
end

function UIModule:CreatePhrasesFrame()
    local frame = CreateWidget("Frame")
    if not frame then return end
    
    frame:SetTitle("RaidCaller Phrases")
    frame:SetLayout("Fill")
    frame:SetPoint("CENTER", self.settingsFrame and self.settingsFrame.frame or "UIParent", "CENTER", 0, -150)
    frame:SetWidth(400)
    frame:SetHeight(350)
    frame.frame:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    
    self.phrasesFrame = frame
    local widgets = self.widgets.phrases

    widgets.phraseGroup = CreateWidget("ScrollFrame")
    widgets.phraseGroup:SetLayout("Flow")
    frame:AddChild(widgets.phraseGroup)
    
    return frame
end

function UIModule:UpdateFrames()
    self.addon:Print("|cffffff00UI:UpdateFrames() triggered.|r")
    self:UpdateSettingsControls()
    self:UpdatePhrasesList()

    if self.addon.UpdateLDBText then
        self.addon:UpdateLDBText()
    end
end

function UIModule:UpdateSettingsControls()
    if not self.settingsFrame then return end
    
    local widgets = self.widgets.settings
    local isAutomatic = self.config:IsAutomaticMode()

    if widgets.autoModeCheckbox then widgets.autoModeCheckbox:SetValue(isAutomatic) end
    if widgets.warningCheckbox then widgets.warningCheckbox:SetValue(self.config:IsSendAsWarning()) end
    if widgets.raidDropdown then widgets.raidDropdown:SetDisabled(isAutomatic) end
    if widgets.bossDropdown then widgets.bossDropdown:SetDisabled(isAutomatic) end
    
    if widgets.raidDropdown then
        self.sortedRaidNames = {}
        for raidName in pairs(self.addon.phrases) do table.insert(self.sortedRaidNames, raidName) end
        table.sort(self.sortedRaidNames)
        local raidList = {}
        for _, raidName in ipairs(self.sortedRaidNames) do raidList[raidName] = raidName end
        widgets.raidDropdown:SetList(raidList, self.sortedRaidNames)
        widgets.raidDropdown:SetValue(self.config:GetManualRaid())
    end

    if widgets.bossDropdown then
        self.sortedBossNames = {}
        local currentRaid = isAutomatic and self.addon.BossDetector.currentZone or self.config:GetManualRaid()
        
        if currentRaid and self.addon.phrases[currentRaid] then
            for bossName in pairs(self.addon.phrases[currentRaid]) do table.insert(self.sortedBossNames, bossName) end
            table.sort(self.sortedBossNames)
            local bossList = {}
            for _, bossName in ipairs(self.sortedBossNames) do bossList[bossName] = bossName end
            widgets.bossDropdown:SetList(bossList, self.sortedBossNames)
            local currentBoss = isAutomatic and self.addon.BossDetector.currentBoss or self.config:GetManualBoss()
            widgets.bossDropdown:SetValue(currentBoss)
        else
            widgets.bossDropdown:SetList({})
            widgets.bossDropdown:SetValue(nil)
        end
    end
end

function UIModule:UpdatePhrasesList()
    if not self.phrasesFrame then return end

    local phraseGroup = self.widgets.phrases.phraseGroup
    if not phraseGroup then return end

    phraseGroup:ReleaseChildren()
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
                    phraseGroup:AddChild(btn)
                end
            end
        end
    end
end

function UIModule:ToggleSettings()
    if not self.settingsFrame then self:CreateSettingsFrame() end
    if not self.settingsFrame then return end
    
    if self.settingsFrame.frame:IsShown() then
        self.settingsFrame:Hide()
    else
        self:UpdateSettingsControls()
        self.settingsFrame:Show()
    end
end

-- FIXED: The toggle logic is now separated into creation and visibility toggling.
function UIModule:TogglePhrases()
    -- If the frame doesn't exist, this is the first click. Create, update, and show it.
    if not self.phrasesFrame then
        self:CreatePhrasesFrame()
        if not self.phrasesFrame then return end -- Creation failed, exit.
        
        self:UpdatePhrasesList()
        self.phrasesFrame:Show()
    else
        -- If the frame exists, this is a subsequent click. Just toggle visibility.
        if self.phrasesFrame.frame:IsShown() then
            self.phrasesFrame:Hide()
        else
            self:UpdatePhrasesList()
            self.phrasesFrame:Show()
        end
    end
end