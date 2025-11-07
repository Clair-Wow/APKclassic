# APKclassic (Azeroth Pet Keeper – Classic MoP)

**Version:** 1.0.2  
**Interface:** 50400  
**Author:** L Clair
**Game:** World of Warcraft – Classic: Mists of Pandaria  

---

### 🐾 Overview
**Azeroth Pet Keeper (APK)** automatically summons one of your favorite battle pets whenever you log in, dismount, or use the summon button.  
This version is designed **specifically for WoW Classic: Mists of Pandaria**, using the `C_PetJournal` API available in that client.

APK helps you keep your favorite companions by your side without needing to open the Pet Journal every time.

---

### ✨ Features
-  **Auto-Summon on Login** – Automatically brings out a random pet when you log in.  
-  **Auto-Summon on Dismount** – Resummons your favorite after mounting or flying.  
-  **Favorites & Blacklist** – Mark pets you prefer or exclude from random picks.  
-  **Zone-Specific Pets** – Assign pets to specific zones (optional).  
-  **Simple UI** – Includes a movable summon button and a minimap button.  
-  **Options Panel** – Toggle features, choose summon behavior, and manage favorites.  
-  **Slash Commands** – Full control via `/apk` commands.

---

### 🔧 Commands
| Command | Description |
|----------|-------------|
| `/apk` or `/apk summon` | Summon a random allowed pet |
| `/apk last` | Re-summon the last pet used |
| `/apk options` | Open the options window |
| `/apk manager` | Open the Pet Manager (favorites, blacklist, counters) |
| `/apk minimap show/hide/reset` | Control the minimap button |
| `/apk ui reset` | Reset the summon button position |
| `/apk zone on/off/add/clear` | Manage zone-specific pets |

---

### 📦 Installation
1. Download the latest ZIP from [GitHub Releases](https://github.com/Clair-Wow/APKclassic/releases).  
2. Extract it so the folder path looks like:  World of Warcraft/classic/Interface/AddOns/APK/
3. Restart WoW and ensure “Load out of date AddOns” is checked on the AddOns screen.  
4. Type `/apk` in chat to confirm it’s loaded.

---

### 🧭 Compatibility
- Built for **Classic: Mists of Pandaria (Interface 50400)**.  
- Works with the in-game Pet Journal API (`C_PetJournal`).  
- Not required for Retail; use the separate [Retail version](https://github.com/Clair-Wow/APK) instead.

---

### 🛠 Development
**GitHub:** [https://github.com/Clair-Wow/APKclassic](https://github.com/Clair-Wow/APKclassic)



