-- UI.lua
-- Creates and manages the user interface. Rewritten for stability and bug fixes.

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

function UIModule:new(addon, config)
    local ui = {}
    ui.addon = addon
    ui.config = config
    ui.mainFrame = nil
    ui.widgets = {}

    function ui:Create()
        self.mainFrame = CreateWidget("Frame")
        if not self.mainFrame then return end -- Critical failure, cannot continue

        self.mainFrame:SetTitle("RaidCaller v5.0")
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
                -- ======== CHECKBOX LOGIC REWRITTEN FOR STABILITY ========
                self.widgets.autoModeCheckbox:SetCallback("OnValueChanged", function()
                    -- Ignore the value from the callback, toggle the saved state directly
                    local currentState = self.config:IsAutomaticMode()
                    local newState = not currentState -- Invert the current state
                    
                    self.addon:Print(string.format("Checkbox Toggled. State changed from '%s' to '%s'", tostring(currentState), tostring(newState)))
                    self.config:SetAutomaticMode(newState)

                    if newState then
                        -- Logic for TURNING ON
                        self.addon:Print("Activating Automatic Mode...")
                        if IsAddOnLoaded("BigWigs") then
                            self.addon:HookBigWigs()
                            if self.addon.BossDetector then self.addon.BossDetector:UpdateZone() end
                        else
                            self.addon:Print("Automatic Mode requires BigWigs, which is not loaded.")
                        end
                    else
                        -- Logic for TURNING OFF
                        self.addon:Print("Deactivating Automatic Mode, returning to Manual.")
                        self.addon:UnhookBigWigs()
                    end
                    
                    self:Update() -- Update the entire UI to reflect the changes
                end)
                controlsGroup:AddChild(self.widgets.autoModeCheckbox)
            end

            self.widgets.raidDropdown = CreateWidget("Dropdown")
            if self.widgets.raidDropdown then
                self.widgets.raidDropdown:SetLabel("Select Raid")
                -- ======== DROPDOWN DEBUGGING ADDED ========
                self.widgets.raidDropdown:SetCallback("OnValueChanged", function(_, event, value)
                    self.addon:Print(string.format("Raid Dropdown Changed. Event: %s, Value: %s", tostring(event), tostring(value)))
                    
                    self.config:SetManualRaid(value)
                    self.config:SetManualBoss(nil)
                    
                    self.addon:Print("Config updated. Calling UI:Update()...")
                    self:Update()
                    self.addon:Print("UI:Update() finished.")
                end)
                controlsGroup:AddChild(self.widgets.raidDropdown)
            end

            self.widgets.bossDropdown = CreateWidget("Dropdown")
            if self.widgets.bossDropdown then
                self.widgets.bossDropdown:SetLabel("Select Boss")
                self.widgets.bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
                    self.config:SetManualBoss(value)
                    self:Update()
                end)
                controlsGroup:AddChild(self.widgets.bossDropdown)
            end
        end

        local separator = CreateWidget("Separator")
        if separator then
            separator:SetFullWidth(true)
            self.mainFrame:AddChild(separator)
        end

        local phraseGroup = CreateWidget("ScrollFrame")
        if phraseGroup then
            phraseGroup:SetLayout("Flow")
            phraseGroup:SetFullWidth(true)
            self.mainFrame:AddChild(phraseGroup)
            
            self.widgets.phraseButtons = {}
            for i = 1, MAX_BUTTONS do
                local btn = CreateWidget("Button")
                if btn then
                    btn:SetFullWidth(true)
                    btn:SetCallback("OnClick", function(widget) addon:SayPhrase(widget.phraseIndex) end)
                    phraseGroup:AddChild(btn)
                    table.insert(self.widgets.phraseButtons, btn)
                end
            end
        end
    end

    function ui:Update()
        if not self.mainFrame then return end
        
        local isAutomatic = self.config:IsAutomaticMode()
        if self.widgets.autoModeCheckbox then self.widgets.autoModeCheckbox:SetValue(isAutomatic) end
        if self.widgets.raidDropdown then self.widgets.raidDropdown:SetDisabled(isAutomatic) end
        if self.widgets.bossDropdown then self.widgets.bossDropdown:SetDisabled(isAutomatic) end

        if self.widgets.raidDropdown then
            local raidList = { [""] = "--- Select a Raid ---" }
            for raidName in pairs(self.addon.phrases) do raidList[raidName] = raidName end
            self.widgets.raidDropdown:SetList(raidList)
            self.widgets.raidDropdown:SetValue(self.config:GetManualRaid())
        end

        if self.widgets.bossDropdown then
            local bossList = { [""] = "--- Select a Boss ---" }
            local selectedRaid = self.config:GetManualRaid()
            if selectedRaid and self.addon.phrases[selectedRaid] then
                for bossName in pairs(self.addon.phrases[selectedRaid]) do bossList[bossName] = bossName end
            end
            self.widgets.bossDropdown:SetList(bossList)
            self.widgets.bossDropdown:SetValue(self.config:GetManualBoss())
        end
        
        local phrases = self.addon:GetCurrentPhrases()
        
        if self.widgets.phraseButtons then
            for i, btn in ipairs(self.widgets.phraseButtons) do
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
    end

    function ui:Toggle()
        if not self.mainFrame then self:Create() end
        if not self.mainFrame then return end -- Check again in case creation failed
        
        if self.mainFrame.frame:IsShown() then
            self.mainFrame:Hide()
        else
            self:Update()
            self.mainFrame:Show()
        end
    end

    return ui
end
