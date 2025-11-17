# CTLD Voice Attack - Quick Reference Card

## Essential Commands (Most Used)

### Troop Operations
```
"load troops"           → Load troops at supply zone
"deploy hold"           → Deploy troops (defensive)
"deploy attack"         → Deploy troops (offensive)
```

### Logistics
```
"build here"            → Build crates at position
"drop all crates"       → Drop all loaded cargo
"show inventory"        → Check zone stock
```

### Navigation
```
"vectors to pickup"     → Find supply zone
"vectors to crate"      → Find dropped crate
"smoke nearest zone"    → Mark closest zone
```

### MEDEVAC (if enabled)
```
"list medevac"          → Show active requests
"vectors to medevac"    → Find crew
"vectors to mash"       → Find hospital
"salvage points"        → Check rewards
```

### Status
```
"show status"           → CTLD system status
"hover coach on/off"    → Toggle pickup guidance
```

---

## Full Command List

### OPERATIONS
| Command | Action |
|---------|--------|
| load troops | Board passengers |
| deploy hold / deploy defend | Unload defensive |
| deploy attack / troops attack | Unload offensive |
| build here / build at position | Build collected crates |
| refresh buildable list | Update build options |

### MEDEVAC (if enabled)
| Command | Action |
|---------|--------|
| list medevac / active medevac requests | List all missions |
| nearest medevac location | Find closest crew |
| salvage points / check salvage | Show points |
| vectors to medevac / medevac vectors | Bearing to crew |
| mash locations / show mash | List hospitals |
| smoke crew locations / mark crews | Mark crews |
| smoke mash zones / mark mash | Mark hospitals |

### LOGISTICS
| Command | Action |
|---------|--------|
| drop one crate / drop crate | Drop single crate |
| drop all crates / drop cargo | Drop all crates |
| mark nearest crate / smoke crate | Re-mark crate |
| show inventory / check inventory | Zone stock |

### FIELD TOOLS
| Command | Action |
|---------|--------|
| create drop zone / mark drop zone | New drop zone |
| smoke green / green smoke | Green smoke |
| smoke red / red smoke | Red smoke |
| smoke white / white smoke | White smoke |
| smoke orange / orange smoke | Orange smoke |
| smoke blue / blue smoke | Blue smoke |

### NAVIGATION
| Command | Action |
|---------|--------|
| vectors to crate / find crate | Find crate |
| vectors to pickup / find pickup zone | Find supply |
| smoke nearest zone / mark nearest zone | Mark nearest |
| smoke all zones / smoke nearby zones | Mark all <5km |
| vectors to mash / find mash | Find MASH |
| enable hover coach / hover coach on | Coach ON |
| disable hover coach / hover coach off | Coach OFF |

### STATUS & ADMIN
| Command | Action |
|---------|--------|
| show status / ctld status | System status |
| draw zones on map / show zones | Draw zones |
| clear map drawings | Clear drawings |
| medevac statistics / medevac stats | MEDEVAC stats |

### QUICK ACCESS
| Command | Same As |
|---------|---------|
| quick pickup / pickup mode | load troops |
| quick deploy / fast deploy | deploy hold |
| quick build / fast build | build here |

---

## F10 Key Binding

**DCS Default (No config needed):**
- On ground: `\` key opens F10
- In air: `RAlt + \` required (backslash alone disabled)

**Voice Attack Profile:**
- All commands use `RAlt + \` (works everywhere)
- Example: "load troops" → **RAlt \ F2 F1 F1**

---

## Common Workflows

### Troop Transport
1. "vectors to pickup"
2. "load troops"
3. Fly to LZ
4. "deploy hold" or "deploy attack"

### Crate Delivery
1. "vectors to pickup"
2. Request crates (manual F10)
3. "vectors to crate"
4. Pick up & deliver
5. "build here"

### MEDEVAC
1. "list medevac"
2. "vectors to medevac"
3. Land near crew (auto-load)
4. "vectors to mash"
5. Land at MASH (auto-unload)
6. "salvage points"

### Zone Recon
1. "smoke all zones" (mark <5km)
2. "draw zones on map" (F10 view)
3. "vectors to pickup" (navigate)
4. "clear map drawings" (cleanup)

---

## Tips
✓ Speak clearly at normal volume
✓ Use alternate phrases if not recognized
✓ Train Voice Attack with your voice
✓ Best when flying stable, not in combat
✗ Don't use for crate requests (too many types)

---

## Troubleshooting
- **Not recognized:** Train profile, try alternate phrase
- **Wrong menu:** Check F10 key (RAlt vs slash)
- **Doesn't navigate:** DCS must be active window
- **MEDEVAC missing:** System not enabled in mission

---

**Print this card for cockpit reference!**

Profile: CTLD_VoiceAttack_Profile.xml
Guide: CTLD_VoiceAttack_Guide.md
CTLD Version: 0.1.0-alpha
