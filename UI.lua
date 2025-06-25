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

function UIModule:new(addon, config)
    local ui = {}
    ui.addon = addon
    ui.config = config
    ui.mainFrame = nil
    ui.widgets = {}
    -- Store the sorted lists to translate indexes back to names
    ui.sortedRaidNames = {} 
    ui.sortedBossNames = {}
    
    -- This function is now fully compatible with the Lua 5.0 interpreter.
    function ui:DebugPrint(...)
        if ui.addon and ui.addon.debug then -- FIX: Changed self.addon to ui.addon for safety in all contexts
            local output = "|cff33ff99DEBUG:|r"
            -- In Lua 5.0, varargs are accessed via the special 'arg' table.
            -- 'arg.n' holds the number of arguments.
            for i = 1, (arg and arg.n or 0) do
                output = output .. " " .. tostring(arg[i])
            end
            ui.addon:Print(output)
        end
    end

    function ui:Create()
        self.mainFrame = CreateWidget("Frame")
        if not self.mainFrame then return end -- Critical failure, cannot continue

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

            -- Create automatic mode checkbox
            self.widgets.autoModeCheckbox = CreateWidget("CheckBox")
            if self.widgets.autoModeCheckbox then
                self.widgets.autoModeCheckbox:SetLabel("Automatic Mode (requires BigWigs)")
                self.widgets.autoModeCheckbox:SetValue(self.config:IsAutomaticMode())
                self.widgets.autoModeCheckbox:SetCallback("OnValueChanged", function()
                    -- FIX: Use 'ui' object, not 'self', as 'self' is not guaranteed in a callback.
                    local currentState = ui.config:IsAutomaticMode()
                    local newState = not currentState
                    ui.config:SetAutomaticMode(newState)
                    if newState then ui.addon:HookBigWigs() else ui.addon:UnhookBigWigs() end
                    ui:Update()
                end)
                controlsGroup:AddChild(self.widgets.autoModeCheckbox)
            end

            -- Create raid dropdown with direct item selection
            self.widgets.raidDropdown = CreateWidget("Dropdown")
            if self.widgets.raidDropdown then
                self.widgets.raidDropdown:SetLabel("Select Raid")
                
                self.raidPulloutOnClick = self.widgets.raidDropdown.pullout and self.widgets.raidDropdown.pullout.OnClick
                
                if self.widgets.raidDropdown.pullout then
                    self.widgets.raidDropdown.pullout.OnClick = function(button)
                        -- FIX: Use 'ui' object, not 'self'. In this callback, 'self' would be the button.
                        local itemIndex = button.userdata and button.userdata.value
                        ui:DebugPrint("Raid pullout clicked, item index:", itemIndex)
                        
                        if ui.raidPulloutOnClick then
                            ui.raidPulloutOnClick(unpack(arg))
                        end
                        
                        if itemIndex and itemIndex > 0 and ui.sortedRaidNames[itemIndex] then
                            local selectedRaidName = ui.sortedRaidNames[itemIndex]
                            ui.addon:Print("Selected raid: " .. selectedRaidName)
                            ui.config:SetManualRaid(selectedRaidName)
                            ui.config:SetManualBoss(nil)
                            ui:Update()
                        end
                    end
                end
                
                self.widgets.raidDropdown:SetCallback("OnValueChanged", function(_, _, value)
                    -- FIX: Use 'ui' object, not 'self'.
                    ui:DebugPrint("Raid dropdown OnValueChanged:", value)
                    
                    if value and value > 0 and ui.sortedRaidNames[value] then
                        local selectedRaidName = ui.sortedRaidNames[value]
                        ui.addon:Print("Selected raid: " .. selectedRaidName)
                        ui.config:SetManualRaid(selectedRaidName)
                        ui.config:SetManualBoss(nil)
                        ui:Update()
                    end
                end)
                
                controlsGroup:AddChild(self.widgets.raidDropdown)
            end

            -- Create boss dropdown with direct item selection
            self.widgets.bossDropdown = CreateWidget("Dropdown")
            if self.widgets.bossDropdown then
                self.widgets.bossDropdown:SetLabel("Select Boss")
                
                self.bossPulloutOnClick = self.widgets.bossDropdown.pullout and self.widgets.bossDropdown.pullout.OnClick
                
                if self.widgets.bossDropdown.pullout then
                    self.widgets.bossDropdown.pullout.OnClick = function(button)
                        -- FIX: Use 'ui' object, not 'self'.
                        local itemIndex = button.userdata and button.userdata.value
                        ui:DebugPrint("Boss pullout clicked, item index:", itemIndex)
                        
                        if ui.bossPulloutOnClick then
                            ui.bossPulloutOnClick(unpack(arg))
                        end
                        
                        if itemIndex and itemIndex > 0 and ui.sortedBossNames[itemIndex] then
                            local selectedBossName = ui.sortedBossNames[itemIndex]
                            ui.addon:Print("Selected boss: " .. selectedBossName)
                            ui.config:SetManualBoss(selectedBossName)
                            ui:Update()
                        end
                    end
                end
                
                self.widgets.bossDropdown:SetCallback("OnValueChanged", function(_, _, value)
                    -- FIX: Use 'ui' object, not 'self'.
                    ui:DebugPrint("Boss dropdown OnValueChanged:", value)
                    
                    if value and value > 0 and ui.sortedBossNames[value] then
                        local selectedBossName = ui.sortedBossNames[value]
                        ui.addon:Print("Selected boss: " .. selectedBossName)
                        ui.config:SetManualBoss(selectedBossName)
                        ui:Update()
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

    function ui:SetDropdownByName(dropdown, sortedList, name)
        if not dropdown or not sortedList or not name then return end
        
        for i, itemName in ipairs(sortedList) do
            if itemName == name then
                dropdown:SetValue(i)
                return i
            end
        end
        
        dropdown:SetValue(nil)
        return nil
    end

    function ui:Update()
        if not self.mainFrame then return end
        
        local isAutomatic = self.config:IsAutomaticMode()
        if self.widgets.autoModeCheckbox then self.widgets.autoModeCheckbox:SetValue(isAutomatic) end
        if self.widgets.raidDropdown then self.widgets.raidDropdown:SetDisabled(isAutomatic) end
        if self.widgets.bossDropdown then self.widgets.bossDropdown:SetDisabled(isAutomatic) end

        if self.widgets.raidDropdown then
            wipe(self.sortedRaidNames)
            for raidName in pairs(self.addon.phrases) do 
                table.insert(self.sortedRaidNames, raidName) 
            end
            table.sort(self.sortedRaidNames)
            
            local raidList = {}
            for i, raidName in ipairs(self.sortedRaidNames) do
                raidList[i] = raidName
            end
            
            self.widgets.raidDropdown:SetList(raidList)
            self:SetDropdownByName(self.widgets.raidDropdown, self.sortedRaidNames, self.config:GetManualRaid())
        end

        if self.widgets.bossDropdown then
            wipe(self.sortedBossNames)
            
            local currentRaid = nil
            if isAutomatic then
                currentRaid = self.addon.BossDetectorModule:GetCurrentRaid()
            else
                currentRaid = self.config:GetManualRaid()
            end
            
            if currentRaid and self.addon.phrases[currentRaid] then
                for bossName in pairs(self.addon.phrases[currentRaid]) do
                    table.insert(self.sortedBossNames, bossName)
                end
                table.sort(self.sortedBossNames)
                
                local bossList = {}
                for i, bossName in ipairs(self.sortedBossNames) do
                    bossList[i] = bossName
                end
                
                self.widgets.bossDropdown:SetList(bossList)
                self:SetDropdownByName(self.widgets.bossDropdown, self.sortedBossNames, self.config:GetManualBoss())
            else
                self.widgets.bossDropdown:SetList({})
                self.widgets.bossDropdown:SetValue(nil)
            end
        end
        
        if self.widgets.phraseGroup and self.widgets.phraseButtons then
            for _, button in ipairs(self.widgets.phraseButtons) do
                button:Hide()
            end
            wipe(self.widgets.phraseButtons)
            self.widgets.phraseGroup:ReleaseChildren()
            
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
                                -- FIX: Use 'ui' object, not 'self'.
                                ui.addon:SayPhrase(widget.phraseIndex)
                            end)
                            self.widgets.phraseGroup:AddChild(btn)
                            table.insert(self.widgets.phraseButtons, btn)
                        end
                    end
                end
            end
        end
    end

    function ui:Toggle()
        if not self.mainFrame then self:Create() end
        if not self.mainFrame then return end
        
        if self.mainFrame.frame:IsShown() then
            self.mainFrame:Hide()
        else
            self:Update()
            self.mainFrame:Show()
        end
    end

    return ui
end