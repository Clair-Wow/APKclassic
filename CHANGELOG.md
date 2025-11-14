# Changelog — APKclassic (Classic Mists of Pandaria)

---

## v1.0.3
**Release Date:** November 2025  
**Summary:** Improved summon logic, eliminated repeat-pet streaks, and added internal buffer for better rotation.

### Changes
- Added **recent-history anti-repeat system**  
  - Tracks the last 10 summoned pets  
  - Auto/random summons avoid recently used pets  
  - Prevents “same pet repeating 80+ times” behavior  
- Removed “prefer last on auto” behavior  
  - Auto-summon no longer reuses the previous pet  
  - `/apk last` still intentionally re-summons the last pet  
- Updated summon logic to guarantee a valid pick, even in small pools  
- Zone-based pools now avoid recent history first, with graceful fallback  
- Improved fallback handling when favorites or zone sets are empty  
- Strengthened handling for indoor/outdoor detection in MoP Classic  
- Updated summon counter tracking → now writes history and counters cleanly  
- Cleaned up internal event handling for login, dismount, and mount transitions

---

## v1.0.2
**Release Date:** November 2025  
**Summary:** First Classic MoP-compatible version.

### Changes
- Converted to **C_PetJournal API** (MoP Classic)  
- Added minimap button with correct rim placement  
- Added `/apk minimap reset` and `/apk ui reset` commands  
- Fixed UI alignment: favorites column, blacklists, counters  
- Improved scroll panel sizing and checkbox templates  
- Added indoor/outdoor/raid summon restrictions  
- General stability improvements

---

## Planned (v1.0.4)
- Optional lock for minimap button  
- Mouse wheel cycling between favorite pets  
- “Compact Mode” display for Pet Manager  
- Optional pet-family filters  
