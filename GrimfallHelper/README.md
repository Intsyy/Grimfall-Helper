# GrimfallHelper 3.0 (WoW 3.3.5a Classless Wildcard Assistant)

**GrimfallHelper 3.0** is the ultimate, all-in-one assistant addon for **Grimfall WoW** (Wrath of the Lich King 3.3.5a), designed specifically to master the classless wildcard progression system.

Whether you're drafting abilities, rerolling spells with scrolls, automating dungeon healing, inspecting hybrid stat caps, generating macros, following real-time combat rotations, or switching specs on the fly, GrimfallHelper streamlines your entire gameplay experience.

---

## 🌟 Key Features

### 1. 🎯 Role Evaluator & "Dream Bar" Auto-Populator
- **Smart Role Detection**: Automatically detects or lets you choose your specialization: **Tank**, **Melee DPS**, **Caster DPS**, **Healer**, or **Solo Hybrid**.
- **Best Spells Scoring Engine**: Evaluates every ability in your classless spellbook, scoring each spell for your role and boosting spells that participate in active synergies by up to **+50%**.
- **1-Click "Fill Dream Bar"**: Automatically maps your optimal Builders, Spenders, Executes, DoTs, Defensives, Heals, and Cooldowns directly into Action Bar slots 1 to 10 outside combat!

### 2. 🗺️ World Map Recommended Zone Levels & Leveling Advisor
- **Continent Hover Enhancements**: Moving your mouse over any zone on the continent map dynamically displays the zone's recommended level bracket (e.g. `Duskwood (18-30)`), color-coded to your player level!
- **Color-Coded Difficulty Indicators**:
  - |cffFF2020Red|r: Extreme Danger (Mundane mobs 3+ levels above you)
  - |cffFF7700Orange|r: Challenging (Quests will be yellow/orange)
  - |cff00FF66Green|r: Optimal (Peak XP and questing speed)
  - |cff55CCFFTeal|r: Slightly Low (Easy clearing / finishing up quests)
  - |cff888888Grey|r: Trivial (Low XP reward)
- **On-Screen World Map Header Badge**: Displays current zone level range, territory status (*Alliance, Horde, Contested, Sanctuary, PvP*), and a full breakdown of all dungeons/raids in the zone with level brackets on hover.
- **Leveling Advisor Command (`/gf zones`)**: Prints an instant list of all ideal leveling zones and dungeons matching your exact character level to chat!

### 3. 🎯 Enemy Nameplate Debuff & DoT Tracker
- **Real-Time Nameplate Auras**: Displays clean, high-visibility icons right above enemy nameplates for any debuffs or damage-over-time effects you have active on them (e.g. **Rend**, **Corruption**, **Moonfire**, **Serpent Sting**, **Sunder Armor**).
- **Live Countdown Timer & Cooldown Spiral**: Every debuff icon includes a live circular cooldown spiral and seconds remaining text (`15s`, `4.2s`, turning red under 3s).
- **Stack Counter**: Multi-stack debuffs (e.g. Sunder Armor, Lacerate) display an active stack count badge.
- **Debuff Type Color-Coded Borders**:
  - **Red**: Bleed / Physical (Rend, Deep Wounds, Sunder Armor, etc.)
  - **Blue**: Magic (Moonfire, Shadow Word: Pain, Immolate, etc.)
  - **Green**: Poison (Deadly Poison, Serpent Sting)
  - **Purple**: Curse (Curse of Agony, etc.)
  - **Brown**: Disease (Blood Plague, Devouring Plague)
- **Combat Log Synchronization**: Persists active DoTs across target swaps so you can track multiple bleeding/rotting targets simultaneously!
- **Quick Toggle**: Toggle anytime via `/gf plates` or in the Settings dashboard.

### 4. 🤖 1-Click Build Exporter for AI (Spells, Talents & Grimfall Runes)
- **Comprehensive Build Extraction**: In 1 click or typing `/gf export`, extracts your entire character build:
  - **Active Grimfall Runes**: Gathers all Runic Enhancements engraved on equipment, learned as spellbook passives, or active as player auras with descriptions.
  - **Allocated Talents**: Extracts every point spent across talent trees with exact talent descriptions.
  - **Learned Spells**: Full list of known abilities grouped by category (Melee Strikes, Spells, DoTs, Heals, Defensives, Buffs, Passives) with highest known rank.
  - **Character Stats**: Level, race, class, AP, SP, Crit %, Hit %, Defense, and Armor.
- **AI-Optimized Markdown**: Formats everything cleanly with an included analysis prompt tailored for ChatGPT, Claude, or Gemini to review synergies and suggest optimizations.
- **Auto-Clipboard Ready**: Opens a modal with all text automatically highlighted—just press **Ctrl + C** and paste into your AI of choice!

### 5. 🔍 Universal Tooltip Classless Enhancer
- **In-Game Tooltip Augmentation**: Injects rich metadata into standard World of Warcraft tooltips anywhere in the game (Spellbook, Action Bars, Chat Links, Talents):
  - **Class of Origin**: Color-coded class badge (e.g. `[Mage]`, `[Warrior]`, `[Paladin]`).
  - **School & Role**: Magic school (Fire, Frost, Shadow, etc.) and category (Melee Attack, DoT, Heal, Defensive).
  - **Wishlist Priority**: Displays if the spell is an `[S-Tier]`, `[A-Tier]`, or `[B-Tier]` target and whether it's already learned.
  - **Active Synergy Triggers**: Shows which active combo packages this ability fuels.
  - **Weapon Requirements**: Instant warning if you do not have the required weapon equipped (Shield, Dagger, Bow/Gun).

### 5. 📖 Unified Classless Spellbook
- **Chaos Solved**: No more searching through 10 generic tabs for your multi-class abilities.
- **Dynamic Multi-Filters**: Filter by Class, Role, Magic School, or Resource.
- **Search & Drag**: Instant search box. Drag abilities directly from the GrimfallHelper window onto your action bars!
- **Max Rank Only Filter**: Cleanly hide lower spell ranks with a single toggle.

### 6. ⭐ Wildcard Wishlist & 8 Pre-Built Meta Templates
- **8 Pre-Built Meta Archetype Templates**: 1-Click loading of pre-optimized wildcard wishlists:
  1. *Pyromancer Archmage* (Ranged Fire burst, Ignite rolling damage, Lava Burst & Chaos Bolt)
  2. *Shatterstrike Cryomancer* (Frost freeze control & Shatter crit multiplier)
  3. *Ironclad Juggernaut Tank* (Max block, mitigation cooldowns & self-sustain)
  4. *Radiant Holy Crusader* (Melee Holy strikes, Judgements, instant heals)
  5. *Shadow Drain Harvester* (Multi-DoT rot & endless leech sustain)
  6. *Tempest Stormcaller* (Rapid Nature shocks, Stormstrike & Lightning procs)
  7. *Bleed-and-Rend Berserker* (Armor tearing physical bleeds & healing debuffs)
  8. *Shadow Infiltrator Assassin* (Guaranteed stealth ambush crits & stun-locks)
- **Target Priority Lists**: Group your custom targets into **S-Tier**, **A-Tier**, and **B-Tier**.
- **Wishlist Alert & Auto-Screenshot**: Audio fanfare, an on-screen banner, and optional automatic screenshots for S-Tier rolls!
- **Build Share Codes**: 1-click **Export** and **Import** build strings (`GFB1:...`) to share builds with friends.

### 7. 🧠 Synergy Engine & Anti-Synergy Checker
- **Build Cohesion Rating**: Computes a dynamic synergy score (0-100) and letter rating (S/A/B/C) based on active combos.
- **Dynamic Archetype Naming**: Automatically titles your hybrid build based on your spells (e.g., *Flame-Forged Juggernaut*, *Frost-Bound Assassin*, *Radiant Crusader*).
- **Conflict & Mismatch Warnings**: Detects weapon requirement mismatches (Shield, Dagger, Ranged) and rage starvation risks.
- **Smart Recommendations**: Suggests missing puzzle pieces to complete powerful active synergies.

### 8. 📊 Hybrid Stat & Rating Cap Inspector
- **AP vs SP Ratio**: Tracks total Attack Power vs Spell Power and provides gearing advice.
- **Hit Cap Tracking**:
  - Melee Special Hit % tracked against the **8.0%** boss cap.
  - Spell Hit % tracked against the **17.0%** boss cap.
- **Crit & Armor**: Compares physical melee crit vs spell crit, and displays exact armor damage reduction %.
- **Tank Defense 540 Tracker**: Calculates total defense skill and remaining defense required for level 83 boss crit immunity.
- **Mana Regeneration (MP5)**: Displays active MP5 inside and outside the 5-second casting rule.

### 9. 🪄 1-Click Smart Macro Generator
- Generates and updates keybindable character macros with one click:
  - `GH_Reroll`: Fast-use macro for Reroll Ability Scrolls.
  - `GH_SmartAttack`: Auto-swaps between ranged shot and melee attack based on distance.
  - `GH_Panic`: Sequential emergency defensive wall (Divine Shield -> Ice Block -> Dispersion -> Shield Wall).
  - `GH_Burst`: Stacks offensive cooldowns (Bloodlust, Avenging Wrath, Recklessness, trinkets).

### 10. ⚔️ Action Bar Presets & 1-Click Auto-Rank Upgrader
- **Action Bar Snapshots**: Save and switch between complete action bar layouts (e.g. *Fire DPS*, *Bleed Tank*, *Holy Healer*, *Solo PvP*).
- **1-Click Auto-Rank Upgrader**: Scans all 120 action bar slots for downranked abilities (e.g., Fireball Rank 2 when you know Rank 5) and upgrades them all in a single click!

### 11. 📜 Wildcard Scroll Tracker & Reroll History
- **Inventory Scanner**: Live bag counter for all Grimfall scrolls (*Ability Reroll Scrolls, Talent Reroll Scrolls, Hand of Fate, Wildcard Tokens*).
- **Reroll History Logger**: Automatically tracks what was acquired, what was rolled, timestamps, and character levels.

### 12. 🛡️ Multi-Resource HUD & Buff Sentinel
- **Floating Movable HUD**: Dynamic Health Bar, color-coded Power Bar (Mana, Rage, Energy, Runic Power), and universal 5-Pip Combo Point display.
- **Missing Buff Sentinel**: Detects if essential personal buffs you know (*Inner Fire, Righteous Fury, Fel Armor, Lightning Shield, Molten Armor, Battle Shout*) are missing out of combat.

### 13. ⚡ Leveling & Automation QoL
- **Auto-Quest Assistant**: Optional auto-accept and turn-in quests for rapid leveling.
- **Auto-Vendor Greys**: Automatically sells all poor/grey junk when visiting vendors with profit summary.
- **Auto-Repair**: Repairs all equipment automatically (supports Guild Bank funds).
- **XP Speedometer**: Tracks session time, XP/hr, estimated time to level, kills, quests, and scrolls farmed per hour.
- **Chat Build Sharing**: Broadcasts your archetype, synergy score, and core spells to Party/Guild chat with `/gf share`.

---

## 🛠️ Installation

1. Download or extract the `GrimfallHelper` folder.
2. Ensure the folder is named `GrimfallHelper`.
3. Place `GrimfallHelper` into your World of Warcraft directory:
   ```
   World of Warcraft/Interface/AddOns/GrimfallHelper/
   ```
4. Launch your **3.3.5a** client, enable GrimfallHelper in the AddOns list, and log in!

---

## ⌨️ Slash Commands

| Command | Action |
| :--- | :--- |
| `/gf` or `/grimfall` | Open / Toggle the Main Dashboard |
| `/gf export` | Export spells, talents & active Grimfall runes to clipboard for AI |
| `/gf zones` | Print recommended leveling zones and dungeons matching your level |
| `/gf plates` | Toggle player debuffs/DoTs (Rend, etc.) on enemy nameplates |
| `/gf dreambar` | Auto-fill action bars with your best role abilities |
| `/gf rank` | Inspect detected highest ranks for all known spells |
| `/gf upgrade` | 1-Click upgrade all downranked action bar spells to max rank |
| `/gf use` | Fast-use first available Reroll Scroll in bags |
| `/gf macro` | Open Action Bars & 1-Click Macro Generator tab |
| `/gf stats` | Open Hybrid Stats & Rating Caps inspector |
| `/gf share` | Share current build to Party/Guild chat |
| `/gf hud` | Toggle floating multi-resource HUD on/off |
| `/gf wish` | Open Wishlist & Build Planner tab |
| `/gf spells` | Open Classless Spellbook browser |
| `/gf synergy` | Open Build Synergy analyzer |
| `/gf quest` | Toggle Auto-Accept & Turn-In Quests |
| `/gf vendor` | Toggle Auto-Vendor Junk on/off |
| `/gf repair` | Toggle Auto-Repair on/off |
| `/gf help` | Display in-game slash command guide |

---

## 🗺️ Minimap Controls

- **Left-Click**: Open / Toggle Main Dashboard.
- **Right-Click**: Fast-use first available Reroll Scroll.
- **Shift + Left-Click**: Toggle Floating Multi-Resource HUD.
- **Hover**: View dynamic tooltip with current archetype, synergy score, scrolls in bags, and XP/hr.
- **Left-Click + Drag**: Reposition icon around the minimap border.

---

## 📦 Technical Specifications

- **Client Compatibility**: WoW 3.3.5a (Wrath of the Lich King, Interface 30300).
- **Dependencies**: **Zero** external libraries required. 100% native WoW Lua 5.1 code.
- **SavedVariables**:
  - `GrimfallHelperDB`: Global account preferences (toggles, window positions).
  - `GrimfallHelperCharDB`: Character-specific wishlist, profiles, reroll logs.
