RaidCaller: Software Architecture Document
1. Introduction & Philosophy
RaidCaller is designed as a lightweight, modular, and maintainable World of Warcraft addon for the 1.12.1 client. Its architecture is built upon the Ace3 addon framework, which provides robust and standardized solutions for common addon tasks such as event handling, saved variables, and GUI creation.

The core philosophy is the separation of concerns, where each major component of the addon is encapsulated in its own Lua file (module). This ensures that the Data Layer, Business Logic, and Presentation Layer are decoupled, making the codebase easier to understand, debug, and extend.

2. Core Components & File Breakdown
The addon is structured across several key files, each with a distinct responsibility.

RaidCaller.lua - The Main Object
This is the central hub and entry point of the addon.

Initialization: It creates the main Ace3 addon object, which serves as the primary namespace.

Module Loading: It orchestrates the initialization of all other modules (Config, BossDetector, UI).

Event Handling: It registers for global game events (e.g., PLAYER_ENTERING_WORLD) and addon messages (from BigWigs), delegating the handling of these events to the appropriate modules.

Slash Command Processor: It registers all /rc slash commands and routes the input to the correct functions (e.g., toggling UI windows, changing debug status).

Core Logic: Contains the primary action function, SayPhrase(), which combines data from other modules to perform its task.

Config.lua - The Data Layer
This module is responsible for all data persistence.

Abstraction: It creates a ConfigModule object that abstracts away the direct manipulation of the SavedVariables table (RaidCallerDB).

API: It provides a clean, explicit API (e.g., IsAutomaticMode(), SetManualRaid(), IsSendAsWarning()) for the rest of the addon to interact with settings.

Engine: It uses the AceDB-3.0 library to handle the loading and saving of the profile-based settings.

BossDetector.lua - The State Management Layer
This module is responsible for determining the addon's current context (the active raid and boss).

Dual Mode Logic:

In Manual Mode, it acts as a simple pass-through, fetching the user's selected raid and boss directly from the Config module.

In Automatic Mode, it maintains its own internal state (currentZone, currentBoss), which is updated by listening to events from the BigWigs addon.

Unified Interface: It exposes a single function, GetCurrentRaidAndBoss(), which returns the correct context regardless of the current mode. This decouples the rest of the addon from having to know whether it's in auto or manual mode.

phrases.lua - The Static Data Store
This is the simplest component. It contains a single, large, hard-coded Lua table that serves as the database for all raid call phrases. The data is structured hierarchically by Raid Name -> Boss Name -> Phrases.

UI.lua - The Presentation Layer
This module is responsible for creating, managing, and updating all user interface elements.

Engine: It is built entirely on the AceGUI-3.0 widget toolkit, ensuring a consistent and recyclable set of UI components.

Two-Window Architecture: It manages two independent frames:

settingsFrame: A larger window containing all configuration widgets (checkboxes, dropdowns).

phrasesFrame: A more compact, movable window that only displays the clickable phrase buttons for the active encounter.

Dynamic Updates: The UpdateFrames() function is the core of the UI logic. It reads the current state from the Config and BossDetector modules and dynamically re-populates all widgets with the correct data (e.g., filling the Boss dropdown when a Raid is selected).

Callbacks: It registers callback functions on all interactive widgets (buttons, dropdowns) that trigger actions in the main addon object or the config module.

Libs/ - The Foundation
This directory contains the Ace3 framework and other third-party libraries (LibDBIcon-1.0, LibDataBroker-1.1). These libraries provide the foundational systems upon which the entire addon is built.

3. Data & Event Flow
The following describes a typical user interaction flow:

User Action: The user selects a new raid from the raidDropdown in the Settings Window.

UI Callback: The OnValueChanged callback in UI.lua for the dropdown is triggered.

State Change: The callback function calls RaidCaller.addon.Config:SetManualRaid() to save the new selection to the database.

UI Refresh: The callback then calls UIModule:UpdateFrames() to refresh all windows.

Update Logic:

UpdateSettingsControls() reads the new raid from Config.lua and updates the dropdowns. It sees that a new raid is selected, so it populates the bossDropdown with the corresponding bosses from the phrases.lua data.

UpdatePhrasesList() is also called. It asks the main addon object for the current phrases.

Phrase Retrieval:

UpdatePhrasesList() calls RaidCaller.addon:GetCurrentPhrases().

GetCurrentPhrases() calls RaidCaller.addon.BossDetector:GetCurrentRaidAndBoss().

BossDetector sees it is in Manual Mode and retrieves the newly selected raid/boss from Config.lua.

GetCurrentPhrases() uses this information to look up the correct phrase list in the phrases.lua data table and returns it.

Render: UpdatePhrasesList() receives the list of phrases and creates the corresponding buttons in the Phrases Window.

This decoupled flow ensures that each component only does its specific job, making the system predictable and maintainable.