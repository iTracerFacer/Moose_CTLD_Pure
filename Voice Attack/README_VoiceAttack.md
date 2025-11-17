# CTLD Voice Attack Integration

This directory contains a complete Voice Attack profile for hands-free navigation of the Moose CTLD (Combat Troop and Logistics Deployment) menu system in DCS World.

## Files in This Package

| File | Purpose |
|------|---------|
| **CTLD_VoiceAttack_Profile.xml** | Voice Attack profile (import this) |
| **CTLD_VoiceAttack_Guide.md** | Complete user guide with all commands |
| **CTLD_VoiceAttack_QuickRef.md** | Quick reference card (print for cockpit) |
| **CTLD_Menu_Structure.md** | Full F10 menu tree diagram |
| **Moose_CTLD.lua** | Source CTLD system (menu structure defined here) |

## Quick Start

### 1. Install
1. Open Voice Attack
2. Import `CTLD_VoiceAttack_Profile.xml`
3. Activate the profile

### 2. F10 Key Binding (Already Configured!)

**DCS Default Behavior:**
- On ground: `\` (backslash) opens F10 menu
- In air: `RAlt + \` required (backslash alone disabled)

**Voice Attack Profile:**
- Uses `RAlt + \` for all commands
- Works both on ground and in air
- **No DCS configuration needed!**

### 3. Test
In DCS, say: **"show status"**
- Should open: F10 → CTLD → Admin/Help → Show CTLD Status

## Most Useful Commands

```
"load troops"           → Load passengers
"deploy hold"           → Unload defensive
"build here"            → Build crates
"drop all crates"       → Drop cargo
"vectors to pickup"     → Find supply zone
"vectors to crate"      → Find crate
"smoke nearest zone"    → Mark zone
"show status"           → System info
```

## Command Categories

- **Troop Operations:** Load, deploy (defensive/offensive)
- **Build Operations:** Build here, refresh list
- **MEDEVAC:** List requests, vectors, MASH locations, salvage points
- **Logistics:** Drop crates, re-mark crate, check inventory
- **Navigation:** Vectors to zones/crates/MASH, smoke zones
- **Field Tools:** Create drop zone, smoke colors
- **Status:** Show status, draw zones, statistics

See `CTLD_VoiceAttack_Guide.md` for complete command list.

## Documentation

### For New Users
Start here: **CTLD_VoiceAttack_Guide.md**
- Installation instructions
- All commands with examples
- Common workflows
- Troubleshooting

### For Flying
Print this: **CTLD_VoiceAttack_QuickRef.md**
- One-page command list
- Essential workflows
- Tips for in-flight use

### For Developers
Reference: **CTLD_Menu_Structure.md**
- Complete F10 menu tree
- Key path tables
- Menu behavior notes
- Source code references

## How It Works

### Direct Navigation
All commands use **direct navigation** - one voice command executes the entire menu path:

```
Say: "load troops"
Sends: RAlt + \ + F2 + F1 + F1
Result: Operations → Troop Transport → Load Troops
```

No step-by-step navigation, no waiting between keys.

### No TTS Feedback
Commands execute silently - DCS provides on-screen feedback.

### All Non-Admin Functions Included
Profile includes:
- ✓ All operational commands
- ✓ All status/info commands
- ✓ Navigation and smoke
- ✓ MEDEVAC operations
- ✗ Specific crate requests (too many types - use manual F10)
- ✗ Debug/admin functions (intentionally excluded)

## Voice Attack Tips

### Improve Recognition
1. Train profile with your voice (Tools → Train Profile)
2. Speak clearly at normal volume
3. Use alternate phrases if not recognized
4. Reduce background noise

### Best Practices
- ✓ Use during stable flight
- ✓ Keep hands free for controls
- ✓ Combine with manual F10 for crate requests
- ✗ Don't use during combat maneuvers
- ✗ Don't use during emergency procedures

## Menu Structure Overview

```
CTLD (F2)
├── Operations (F1)
│   ├── Troop Transport
│   ├── Build
│   └── MEDEVAC
├── Logistics (F2)
│   ├── Request Crate
│   ├── Recipe Info
│   ├── Crate Management
│   └── Show Inventory
├── Field Tools (F3)
├── Navigation (F4)
└── Admin/Help (F5)
```

Full structure: `CTLD_Menu_Structure.md`

## Limitations

### Not Included
1. **Crate Requests:** Too many types (dozens of vehicles, SAMs, etc.)
   - Use manual F10: CTLD → Logistics → Request Crate
   
2. **Typed Troop Loading:** Submenu with 4+ troop types
   - Use manual F10: CTLD → Operations → Troop Transport → Load Troops (Type)
   
3. **Advanced Build Menu:** Dynamic list of buildable items
   - Use manual F10: CTLD → Operations → Build → Build (Advanced)
   
4. **Debug Commands:** Admin logging controls
   - Not needed for normal operations

### Why These Are Excluded
- **Crate requests:** Mission-specific, too many variations
- **Typed troops:** Rare use case, 4+ submenu items
- **Advanced build:** Dynamic content, better with manual selection
- **Debug:** Admin-only, not for regular flight ops

Use voice commands for quick actions, manual F10 for detailed selections.

## Compatibility

- **CTLD Version:** 0.1.0-alpha (Moose_CTLD_Pure)
- **Voice Attack:** 1.8+ (tested on 1.10)
- **DCS World:** Current stable/open beta
- **Menu Type:** Per-player (MENU_GROUP)

## Customization

### Add New Commands
1. Open profile in Voice Attack
2. Study menu structure: `CTLD_Menu_Structure.md`
3. Create command with key sequence
4. Test in DCS

### Update for Menu Changes
1. Check `Moose_CTLD.lua` function `BuildGroupMenus()` (~line 2616)
2. Update key sequences in Voice Attack
3. Update documentation files
4. Test all modified commands

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Command not recognized | Train profile, try alternate phrase |
| Wrong menu opens | Verify DCS default binding (RAlt + \), check Controls settings |
| Menu doesn't navigate | DCS must be active window, F10 not already open |
| MEDEVAC missing | System not enabled in mission |
| Works on ground but not in air | Expected! Profile uses RAlt + \ (works in air) |

Full troubleshooting: `CTLD_VoiceAttack_Guide.md`

## Examples

### Troop Transport Mission
```
1. Say: "vectors to pickup"      → Find supply zone
2. Fly to zone
3. Say: "load troops"             → Board passengers
4. Fly to LZ
5. Say: "deploy hold"             → Unload defensive
```

### Crate Logistics Mission
```
1. Say: "vectors to pickup"       → Find supply zone
2. Manual F10 to request crates   → (Too many types for voice)
3. Say: "vectors to crate"        → Find spawned crate
4. Pick up and fly to target
5. Say: "build here"              → Deploy at destination
```

### MEDEVAC Mission
```
1. Say: "list medevac"            → Check active requests
2. Say: "vectors to medevac"      → Find nearest crew
3. Land nearby (auto-load)
4. Say: "vectors to mash"         → Find hospital
5. Land at MASH (auto-unload)
6. Say: "salvage points"          → Check rewards
```

### Reconnaissance
```
1. Say: "smoke all zones"         → Mark nearby zones
2. Say: "draw zones on map"       → See all zones on F10
3. Manual F10 map navigation
4. Say: "clear map drawings"      → Clean up
```

More workflows: `CTLD_VoiceAttack_Guide.md`

## Support

### If Menu Structure Changes
Menu structure is defined in `Moose_CTLD.lua`:
- Function: `CTLD:BuildGroupMenus(group)`
- Line: ~2616

Compare with `CTLD_Menu_Structure.md` to identify changes.

### Profile Updates
1. Check code for menu changes
2. Update Voice Attack key sequences
3. Update documentation
4. Test all commands

### Help Resources
- CTLD source code: `Moose_CTLD.lua`
- Menu diagram: `CTLD_Menu_Structure.md`
- Full guide: `CTLD_VoiceAttack_Guide.md`
- Quick ref: `CTLD_VoiceAttack_QuickRef.md`

## Version History

### Version 1.0 (Current)
- Initial release
- 40+ voice commands
- Direct navigation (no step-by-step)
- No TTS feedback
- Supports RAlt or slash key for F10
- All non-admin functions included
- Comprehensive documentation

## Credits

- **CTLD System:** Moose_CTLD_Pure custom implementation
- **Voice Attack:** VoiceAttack by VoiceAttack.com
- **DCS World:** Eagle Dynamics
- **MOOSE Framework:** FlightControl-Master

---

**Ready to fly hands-free? Import the profile and start with "show status"!**

Questions? See `CTLD_VoiceAttack_Guide.md` for detailed help.
