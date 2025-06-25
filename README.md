# RaidCaller

**Your essential co-pilot for clear and effective raid leading in Vanilla WoW.**

RaidCaller is a lightweight, modern addon for the World of Warcraft 1.12.1 client, designed to streamline communication for raid leaders and assistants. It replaces the need to manually type commands during a hectic boss fight with a simple, powerful, and intuitive interface.

Spend less time typing and more time leading.

## ✨ Core Features

* **💬 Instant Raid Calls:** Click a button to instantly send a pre-written, instructional message to either `/raid` or as a prominent `/raidwarning`.

* **📚 Extensive Phrase Library:** Comes pre-loaded with common, effective phrases for every major boss in Onyxia's Lair, Molten Core, Blackwing Lair, Zul'Gurub, and Ahn'Qiraj (both AQ20 and AQ40).

* **🧠 Smart Dual-Window UI:**

  * **Settings Window:** A clean interface for pre-fight setup. Select the raid, boss, and message type.

  * **Phrases Window:** A separate, compact window showing only the relevant phrases for the current fight. Set up your calls, close the settings, and keep the small phrase list on screen.

* **🤖 Automatic & Manual Modes:**

  * **Manual:** You have full control to select the raid and boss.

  * **Automatic:** Integrates seamlessly with **BigWigs Bossmods** to detect the active encounter and load the correct phrases for you, automatically.

* **🔌 LDB / Minimap Support:** Includes a fully-featured **LibDataBroker (LDB)** plugin. If you use a display addon like Titan Panel, FuBar, or just want a minimap icon, RaidCaller integrates perfectly.

  * Shows current mode and boss at a glance.

  * Left-click to toggle the settings panel.

## 🚀 How to Use

### Basic Workflow

1. **Open Settings:** Type `/rc` or left-click the minimap icon to open the main settings window.

2. **Configure:**

   * Choose your mode (`Manual` or `Automatic`).

   * Choose your message type (`Raid` or `Raid Warning`).

   * In Manual mode, select the desired Raid and Boss from the dropdowns.

3. **Open Phrases:** Click the "Toggle Phrases" button to show the compact caller window.

4. **Lead the Raid:** Close the settings window. Use the Phrases window to make your calls with a single click.

### Slash Commands

The addon can be controlled with simple slash commands:

| **Command** | **Alias** | **Description** | 
 | ----- | ----- | ----- | 
| `/raidcaller settings` | `/rc` | Toggles the main settings window. | 
| `/raidcaller phrases` | `/rc phrases` | Toggles the separate phrases window. | 
| `/raidcaller debug` | `/rc debug` | Toggles debug message output for troubleshooting. | 
| `/raidcaller say [number]` | `/rc say [number]` | Says the phrase corresponding to the number. (Used for keybindings) | 