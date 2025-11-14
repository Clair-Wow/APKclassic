# APKclassic — Azeroth Pet Keeper for Classic MoP

**Version:** 1.0.3  
**Game Client:** World of Warcraft Classic — Mists of Pandaria  
**Interface:** 50400  
**Author:** L.Clair  

---

## 🐾 Overview
**Azeroth Pet Keeper (APKclassic)** automatically summons one of your companion battle pets while you play.  
This version is built specifically for **Classic MoP**, using the Pet Journal API introduced in Patch 5.x.

Summon pets on login, when dismounting, or manually through the summon button or minimap button.

APK keeps your favorite companions with you without constant journal juggling.

---

## ✨ Features
- 🐾 **Automatic Summoning**
  - On login  
  - On dismount  
  - With indoor/outdoor/raid rules  
- 🔀 **Anti-Repeat Pet Rotation (New in v1.0.3!)**
  - Tracks last 10 summoned pets  
  - Prevents back-to-back repeats  
  - `/apk last` still intentionally re-summons the last pet  
- 💖 **Favorites and Blacklists**
- 🌍 **Zone-Based Pet Sets** (optional)
- 🎯 **Simple UI**
  - Movable main summon button  
  - Rim-attached minimap button  
  - Detailed Pet Manager  
- 🛠 **Custom Options Panel**
- 🔄 **Slash Commands** for full control

---

## 🔧 Commands

| Command | Action |
|--------|--------|
| `/apk` / `/apk summon` | Summon a random pet |
| `/apk last` | Re-summon the previous pet |
| `/apk options` | Open the Options window |
| `/apk manager` | Open the Pet Manager |
| `/apk minimap show` | Show the minimap button |
| `/apk minimap hide` | Hide the minimap button |
| `/apk minimap reset` | Reset minimap button to default position |
| `/apk ui reset` | Reset the main summon button |
| `/apk zone on/off` | Enable or disable zone-based sets |
| `/apk zone add` | Add current pet to current zone |
| `/apk zone clear` | Clear zone set |

---

## 🧭 Compatibility
- Supports **Classic MoP** (`Interface: 50400`)  
- Uses `C_PetJournal` for pet handling  
- Does **not** support Retail or Classic Era

---

## 🛠 Development
Repo: https://github.com/Clair-Wow/APKclassic


🧾 License

This addon is released under the MIT License.

❤️ Credits

Classic MoP version built and maintained by Clair-Wow

Based on the original Retail edition of Azeroth Pet Keeper
