-- UI.lua
-- Creates and manages the user interface. Rewritten for stability.

RaidCaller = RaidCaller or {}

local UIModule = {}
RaidCaller.UIModule = UIModule

local AceGUI = LibStub("AceGUI-3.0")
local MAX_BUTTONS = 15

function UIModule:new(addon, config)
    local ui = {}
    ui.addon = addon
    ui.config = config
    ui.mainFrame = nil
    ui.widgets = {}

    -- Create the main UI frame and all its widgets
    function ui:Create()
        local frame = AceGUI:Create("Frame")
        frame:SetTitle("RaidCaller v4.0")
        frame:SetLayout("Flow")
        frame:SetPoint("CENTER")
        frame:SetWidth(400)
        frame:SetHeight(500)
        frame:Hide()
        self.mainFrame = frame

        -- Container for top controls
        local controlsGroup = AceGUI:Create("SimpleGroup")
        controlsGroup:SetLayout("Flow")
        controlsGroup:SetFullWidth(true)
        frame:AddChild(controlsGroup)
        
        -- NEW: Checkbox for Automatic Mode
        local autoModeCheckbox = AceGUI:Create("CheckBox")
        autoModeCheckbox:SetLabel("Automatic Mode (requires BigWigs)")
        autoModeCheckbox:SetValue(self.config:IsAutomaticMode())
        autoModeCheckbox:SetCallback("OnValueChanged", function(_, _, value)
            self.config:SetAutomaticMode(value)
            if value and IsAddOnLoaded("BigWigs") then
                self.addon:HookBigWigs()
                self.addon.BossDetector:UpdateZone()
            elseif not value then
                self.addon:UnhookBigWigs()
            end
            self:Update() -- Update the UI to reflect the mode change
        end)
        controlsGroup:AddChild(autoModeCheckbox)
        self.widgets.autoModeCheckbox = autoModeCheckbox

        -- Manual Selection Dropdowns
        local raidDropdown = AceGUI:Create("Dropdown")
        raidDropdown:SetLabel("Select Raid")
        raidDropdown:SetCallback("OnValueChanged", function(_, _, value)
            self.config:SetManualRaid(value)
            self.config:SetManualBoss(nil) -- Reset boss selection when raid changes
            self:Update()
        end)
        controlsGroup:AddChild(raidDropdown)
        self.widgets.raidDropdown = raidDropdown

        local bossDropdown = AceGUI:Create("Dropdown")
        bossDropdown:SetLabel("Select Boss")
        bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
            self.config:SetManualBoss(value)
            self:Update()
        end)
        controlsGroup:AddChild(bossDropdown)
        self.widgets.bossDropdown = bossDropdown
        
        -- Separator
        local separator = AceGUI:Create("Separator")
        separator:SetFullWidth(true)
        frame:AddChild(separator)

        -- Phrase buttons container
        local phraseGroup = AceGUI:Create("ScrollFrame")
        phraseGroup:SetLayout("Flow")
        phraseGroup:SetFullWidth(true)
        frame:AddChild(phraseGroup)
        
        self.widgets.phraseButtons = {}
        for i = 1, MAX_BUTTONS do
            local btn = AceGUI:Create("Button")
            btn:SetFullWidth(true)
            btn:SetCallback("OnClick", function(widget) addon:SayPhrase(widget.phraseIndex) end)
            phraseGroup:AddChild(btn)
            table.insert(self.widgets.phraseButtons, btn)
        end
    end

    -- Update the UI contents based on the current addon state (REWRITTEN FOR STABILITY)
    function ui:Update()
        if not self.mainFrame then return end
        
        local isAutomatic = self.config:IsAutomaticMode()
        self.widgets.autoModeCheckbox:SetValue(isAutomatic)

        -- Enable/disable manual controls based on mode
        self.widgets.raidDropdown:SetDisabled(isAutomatic)
        self.widgets.bossDropdown:SetDisabled(isAutomatic)

        -- 1. Populate Raid Dropdown always
        local raidList = { [""] = "--- Select a Raid ---" } -- Add a placeholder
        for raidName in pairs(self.addon.phrases) do raidList[raidName] = raidName end
        self.widgets.raidDropdown:SetList(raidList)
        local selectedRaid = self.config:GetManualRaid()
        self.widgets.raidDropdown:SetValue(selectedRaid)

        -- 2. Populate Boss Dropdown only if a raid is selected
        local bossList = { [""] = "--- Select a Boss ---" }
        if selectedRaid and self.addon.phrases[selectedRaid] then
            for bossName in pairs(self.addon.phrases[selectedRaid]) do bossList[bossName] = bossName end
        end
        self.widgets.bossDropdown:SetList(bossList)
        local selectedBoss = self.config:GetManualBoss()
        self.widgets.bossDropdown:SetValue(selectedBoss)

        -- 3. Get current phrases (this is now safe)
        local phrases = self.addon:GetCurrentPhrases()
        
        -- 4. Update phrase buttons
        for i, btn in ipairs(self.widgets.phraseButtons) do
            -- The check 'phrases and phrases[i]' is robust and handles nil values
            if phrases and phrases[i] then
                btn:SetText(i .. ". " .. phrases[i])
                btn.phraseIndex = i
                btn:SetDisabled(false)
                btn.frame:Show()
            else
                btn.frame:Hide()
            end
        end
    end

    -- Toggle UI visibility
    function ui:Toggle()
        if not self.mainFrame then self:Create() end
        
        if self.mainFrame.frame:IsShown() then
            self.mainFrame:Hide()
        else
            self:Update() -- Always update before showing
            self.mainFrame:Show()
        end
    end

    return ui
end
