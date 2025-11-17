# DCS CTLD Voice Attack Profile Guide

## Overview
This Voice Attack profile provides voice command navigation for the Moose CTLD (Combat Troop and Logistics Deployment) menu system in DCS World. All commands use direct navigation - saying the command automatically navigates through the entire F10 menu path.

## Installation

### 1. Import the Profile
1. Open Voice Attack
2. Click the wrench icon (Edit Profile)
3. Click "Import Profile"
4. Navigate to `CTLD_VoiceAttack_Profile.xml`
5. Select the profile and click OK

### 2. DCS Key Binding (No Configuration Needed!)
The profile uses **Right Alt + Backslash** (`RAlt + \`) which works in all situations:

- **On the ground:** Backslash `\` alone opens F10, but `RAlt + \` also works
- **In the air:** Only `RAlt + \` works (backslash alone is disabled)

The profile uses `RAlt + \` for all commands, ensuring compatibility both on ground and in air.

**No DCS configuration changes needed** - this is the default binding!

## F10 Key Binding

### How DCS F10 Menu Works
- **On ground:** Backslash `\` key opens F10 menu
- **In the air:** `\` is disabled, must use `Right Alt + \`

### Voice Attack Profile
All commands use **`RAlt + \`** which works in both situations:
```
"load troops" → RAlt + \ + F2 + F1 + F1
"build here" → RAlt + \ + F2 + F2 + F1
"vectors to pickup" → RAlt + \ + F4 + F2
```

This ensures voice commands work whether you're on the ground or flying!

## Command Reference

### OPERATIONS: Troop Transport

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "load troops" | Load troops at supply zone | Operations → Troop Transport → Load Troops |
| "deploy troops"<br>"deploy hold"<br>"deploy defend" | Deploy troops in defensive posture | Operations → Troop Transport → Deploy [Hold Position] |
| "deploy attack"<br>"troops attack" | Deploy troops with attack orders | Operations → Troop Transport → Deploy [Attack] |

### OPERATIONS: Build

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "build here"<br>"build at position" | Build collected crates at location | Operations → Build → Build Here |
| "refresh buildable list"<br>"refresh build list" | Update list of buildable items | Operations → Build → Refresh Buildable List |

### OPERATIONS: MEDEVAC (if enabled)

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "list medevac"<br>"active medevac requests" | Show all active MEDEVAC missions | Operations → MEDEVAC → List Active MEDEVAC Requests |
| "nearest medevac location"<br>"medevac location" | Show nearest MEDEVAC crew location | Operations → MEDEVAC → Nearest MEDEVAC Location |
| "salvage points"<br>"check salvage" | Display coalition salvage points | Operations → MEDEVAC → Coalition Salvage Points |
| "vectors to medevac"<br>"medevac vectors" | Get bearing/range to nearest crew | Operations → MEDEVAC → Vectors to Nearest MEDEVAC |
| "mash locations"<br>"show mash" | List all MASH zones | Operations → MEDEVAC → MASH Locations |
| "smoke crew locations"<br>"mark crews" | Pop smoke at MEDEVAC crew positions | Operations → MEDEVAC → Pop Smoke at Crew Locations |
| "smoke mash zones"<br>"mark mash" | Pop smoke at MASH delivery zones | Operations → MEDEVAC → Pop Smoke at MASH Zones |

### LOGISTICS: Crate Management

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "drop one crate"<br>"drop crate" | Drop single loaded crate | Logistics → Crate Management → Drop One Loaded Crate |
| "drop all crates"<br>"drop cargo" | Drop all loaded crates | Logistics → Crate Management → Drop All Loaded Crates |
| "mark nearest crate"<br>"smoke crate"<br>"remark crate" | Re-mark closest crate with smoke | Logistics → Crate Management → Re-mark Nearest Crate |
| "show inventory"<br>"check inventory"<br>"zone inventory" | Display zone inventory | Logistics → Show Inventory at Nearest Zone |

### FIELD TOOLS

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "create drop zone"<br>"mark drop zone" | Create new drop zone at position | Field Tools → Create Drop Zone (AO) |
| "smoke green"<br>"green smoke" | Pop green smoke at location | Field Tools → Smoke My Location → Green |
| "smoke red"<br>"red smoke" | Pop red smoke at location | Field Tools → Smoke My Location → Red |
| "smoke white"<br>"white smoke" | Pop white smoke at location | Field Tools → Smoke My Location → White |
| "smoke orange"<br>"orange smoke" | Pop orange smoke at location | Field Tools → Smoke My Location → Orange |
| "smoke blue"<br>"blue smoke" | Pop blue smoke at location | Field Tools → Smoke My Location → Blue |

### NAVIGATION

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "vectors to crate"<br>"find crate"<br>"nearest crate" | Get bearing/range to nearest crate | Navigation → Request Vectors to Nearest Crate |
| "vectors to pickup"<br>"find pickup zone"<br>"nearest pickup" | Get bearing/range to pickup zone | Navigation → Vectors to Nearest Pickup Zone |
| "smoke nearest zone"<br>"mark nearest zone" | Smoke closest zone (any type) | Navigation → Smoke Nearest Zone |
| "smoke all zones"<br>"mark all zones"<br>"smoke nearby zones" | Smoke all zones within 5km | Navigation → Smoke All Nearby Zones (5km) |
| "vectors to mash"<br>"find mash"<br>"nearest mash" | Get bearing/range to MASH | Navigation → Vectors to Nearest MASH |
| "enable hover coach"<br>"hover coach on" | Enable hover pickup guidance | Navigation → Hover Coach: Enable |
| "disable hover coach"<br>"hover coach off" | Disable hover pickup guidance | Navigation → Hover Coach: Disable |

### STATUS & ADMIN

| Voice Command | Action | Menu Path |
|--------------|--------|-----------|
| "show status"<br>"ctld status"<br>"check status" | Display CTLD system status | Admin/Help → Show CTLD Status |
| "draw zones on map"<br>"show zones"<br>"mark zones on map" | Draw all zones on F10 map | Admin/Help → Draw CTLD Zones on Map |
| "clear map drawings"<br>"clear map marks"<br>"remove zone marks" | Remove zone drawings from map | Admin/Help → Clear CTLD Map Drawings |
| "medevac statistics"<br>"medevac stats"<br>"show medevac stats" | Display MEDEVAC statistics | Admin/Help → Show MEDEVAC Statistics |

### QUICK ACCESS COMMANDS

These are alternate phrases for commonly used functions:

| Voice Command | Equivalent To |
|--------------|---------------|
| "quick pickup"<br>"pickup mode" | "load troops" |
| "quick deploy"<br>"fast deploy" | "deploy troops" |
| "quick build"<br>"fast build" | "build here" |

## Usage Tips

### 1. Voice Recognition Accuracy
- Speak clearly and at normal volume
- Pause briefly between words for best recognition
- If a command doesn't work, try an alternate phrase
- Train Voice Attack with your voice for better accuracy

### 2. Menu Navigation Timing
- Commands execute instantly with no delays
- DCS menu system is fast - no need to wait between commands
- If you're in a different menu, the command will navigate from wherever you are

### 3. Common Workflows

**Troop Transport Mission:**
1. "vectors to pickup" (find supply zone)
2. "load troops" (board passengers)
3. Fly to destination
4. "deploy hold" or "deploy attack" (unload with orders)

**Crate Logistics Mission:**
1. "vectors to pickup" (find supply zone)
2. Use manual F10 menu to request specific crates
3. "vectors to crate" (find spawned crate)
4. Pick up crate
5. "build here" (deploy at destination)

**MEDEVAC Mission:**
1. "list medevac" (check active requests)
2. "vectors to medevac" (find nearest crew)
3. Pick up crew (auto-load when landed nearby)
4. "vectors to mash" (find hospital)
5. Deploy at MASH (auto-unload)
6. "salvage points" (check rewards)

**Reconnaissance:**
1. "smoke all zones" (mark nearby objectives)
2. "draw zones on map" (see all zones on F10)
3. "vectors to pickup" (return to base)
4. "clear map drawings" (clean up map)

### 4. Combat Situations
Voice commands work best when:
- ✓ Flying stable (not in combat maneuvers)
- ✓ Hands free for flight controls
- ✓ Clear of radio chatter/background noise
- ✗ Not recommended during combat or emergency procedures

### 5. Request Crate Limitation
**Note:** The profile does NOT include voice commands for requesting specific crate types because:
- There are dozens of crate types (vehicles, SAMs, FOBs, etc.)
- Categories vary by mission configuration
- Manual F10 navigation (F2 → Logistics → Request Crate) is more practical

Use voice commands for navigation/status, manual F10 for crate requests.

## Troubleshooting

### Command Not Recognized
1. Check Voice Attack is running and profile is active
2. Train Voice Attack with your voice (Tools → Train Profile)
3. Try alternate phrases for the command
4. Verify microphone input levels

### Wrong Menu Opens
1. Verify DCS is using default key bindings (RAlt + \ for F10)
2. Check that backslash key isn't rebound in DCS controls
3. Try manual RAlt + \ to verify F10 menu opens

### Command Works But Menu Doesn't Navigate
1. Verify DCS is the active window
2. Check F10 menu is not already open
3. Ensure no other key bindings conflict with F-keys
4. Try manual navigation to verify menu structure matches profile

### MEDEVAC Commands Not Available
- These commands only work if MEDEVAC system is enabled in the mission
- Check mission briefing or use "show status" to verify MEDEVAC is active

## Profile Customization

### Adding New Commands
1. Open Voice Attack profile editor
2. Click "New Command"
3. Set "When I say" to your phrase
4. Add Action: "Send keys to active window"
5. Enter key sequence (e.g., `{RALT}{F2}{F1}{F1}`)
6. Save command

### Modifying Existing Commands
1. Find command in list
2. Click "Edit"
3. Modify "When I say" phrases
4. Update key sequence if menu structure changed
5. Save changes

### Key Sequence Format
- `{RALT}` = Right Alt key
- `\\` = Backslash key (escaped in XML)
- `{F1}` through `{F9}` = Function keys
- Example: `{RALT}\\{F2}{F3}{F1}` = RAlt, \, F2, F3, F1 in sequence

## Menu Structure Reference

```
CTLD (Root - F2)
├── F1: Operations
│   ├── F1: Troop Transport
│   ├── F2: Build
│   └── F3: MEDEVAC
├── F2: Logistics
│   ├── F1: Request Crate
│   ├── F2: Recipe Info
│   ├── F3: Crate Management
│   └── F4: Show Inventory
├── F3: Field Tools
├── F4: Navigation
└── F5: Admin/Help
```

See full menu tree diagram in main documentation.

## Version Information

- **Profile Version:** 1.0
- **CTLD Version:** 0.1.0-alpha (Moose_CTLD_Pure)
- **Voice Attack Version:** 1.8+ (tested on 1.10)
- **DCS Version:** Compatible with current stable/open beta

## Support & Updates

If the menu structure changes in future CTLD updates:
1. Check `Moose_CTLD.lua` function `BuildGroupMenus()` (around line 2616)
2. Update key sequences in Voice Attack profile
3. Test each command to verify navigation

## Credits

- **CTLD System:** Moose_CTLD_Pure custom implementation
- **Voice Attack:** VoiceAttack by VoiceAttack.com
- **DCS World:** Eagle Dynamics

---

**Happy Flying! 🚁**
