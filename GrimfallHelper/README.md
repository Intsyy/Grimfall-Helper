# GrimfallHelper (WoW 3.3.5a Classless Wildcard Assistant)

**GrimfallHelper** is the ultimate character build inspector, rune compendium, and build sharing addon for **Grimfall WoW** (Wrath of the Lich King 3.3.5a), designed specifically to master the classless wildcard progression system.

Whether you're inspecting gear and item levels, reviewing active mystic enchantments, browsing the 2,600+ rune database, organizing your classless spellbook, sending builds to friends in-game via whisper, or exporting your setup for AI analysis, GrimfallHelper streamlines your entire wildcard experience.

---

## 🌟 Key Features

### 1. 🛡️ Character Build Inspector & Build Value Evaluator (Tab 1: My Build)
- **Full Equipment & Item Level Inspect**: Visualizes all 19 equipment slots with item quality borders, icons, and exact item levels (`ilvl`).
- **Comprehensive Attribute Breakdown**:
  - **Primary Attributes**: Full numerical support for Strength, Agility, Stamina, Intellect, and Spirit without truncation.
  - **Combat & Defense**: Armor, Attack Power, Spell Power, Melee Crit %, Spell Crit %, Melee Hit %, Spell Hit %, and Defense rating.
- **Active Grimfall Runes**: Detects all engraved Runic Enhancements (Mystic Enchantments) across your gear and spellbook with quality coloring (Common to Legendary) and full effect descriptions.
- **Talents Overview**: Scans and displays all spent talent points across your talent trees with full ability details.
- **Build Value Score & Archetype Classification**: Evaluates your combination of runes, stats, and abilities to calculate a dynamic **Build Power Score** and assign a role archetype (e.g. *Blood-Forged Juggernaut Tank*, *Radiant Holy Crusader*, *Shatterstrike Cryomancer*).
- **1-Click Actions**: Instant buttons to send your build directly to your target player, share a summary to chat, or refresh stats.

### 2. 📬 Shared Builds Session Inbox & Player Inspector (Tab 2: Shared Builds)
- **Real-Time In-Game Build Sharing**: Receive full character builds sent by other players over chat/whisper (`/gf send <player>`).
- **Automatic Whisper Detection**: The addon listens in the background for incoming build transmissions and automatically catalogs them without interrupting your gameplay.
- **Inbox Overview List**: Displays all received player builds for your current session with headline details:
  - Player Name, Level, Race, and Class.
  - Role Archetype & Build Power Score.
  - Average Item Level (`ilvl`) and Active Runes count.
- **Detailed Build Inspector**: Click on any player in the inbox to view their entire setup:
  - Complete equipped gear list with item levels.
  - Full primary and combat attributes.
  - Active runes and passive enchantments with descriptions.
  - Full talent tree allocation.
- **Session Memory**: Builds are safely kept in memory during your play session for instant comparison and review.

### 3. 📖 Unified Classless Spellbook (Tab 3: Spellbook)
- **Solves Classless Spell Chaos**: Eliminates the frustration of searching through dozens of generic spellbook tabs.
- **Multi-Filter Navigation**:
  - **Role & Category**: All, Melee Attacks, Spells / Ranged, Healing, Defensives, Buffs & Passives.
  - **Magic School**: Physical, Holy, Fire, Frost, Nature, Shadow, Arcane.
  - **Resource**: Mana, Rage, Energy, Runic Power, None.
- **Instant Search Box**: Real-time text filter by spell name.
- **Max Rank Only Filter**: Toggle between viewing all spell ranks or only your highest learned ranks.
- **Drag & Drop**: Drag abilities directly from the GrimfallHelper window onto your action bars.

### 4. 🤖 1-Click Build Exporter for AI & Compact Code Generator (Tab 4: Export & Share)
- **AI-Optimized Markdown Export**: With 1 click or typing `/gf export`, formats your entire character into a structured Markdown profile:
  - Gear & item levels, attributes, active runes with descriptions, talent tree distribution, and known spells grouped by role.
  - Pre-packaged with an expert analysis prompt tailored for **ChatGPT**, **Claude**, or **Gemini** to review synergies, stat cap deficiencies, and gear recommendations.
- **Compact Build Share Codes**: Generates short, shareable build strings (`GF#...`) to post in Discord, guild forums, or community channels.
- **Direct Player Whisper**: Quick input box to send your full build to any player by character name.
- **Party & Guild Chat Broadcast**: Share your archetype headline and score directly to your group.

### 5. 📜 2,615 Rune List & Compendium (Tab 5: Rune List)
- **Complete Rune Database**: Searchable offline compendium containing all **2,615 Grimfall Mystic Enchantments**.
- **Instant Search**: Filter by rune name or effect text in real time.
- **Slot & Rarity Filters**:
  - Filter by gear slot (Head, Shoulders, Chest, Waist, Legs, Feet, Wrist, Hands, Weapon, Shield/Offhand, Ring, Trinket, etc.).
  - Filter by rarity tier: Common, Uncommon, Rare, Epic, Legendary.
- **In-Depth Tooltips**: Hover over any rune to read its exact spell mechanics and values.

### 6. 🗺️ World Map Recommended Zone Levels & Leveling Advisor
- **Map Zone Level Overlays**: Moving your mouse over any zone on the continent map dynamically displays the zone's recommended level bracket (e.g. `Duskwood (18-30)`), color-coded to your character level:
  - **Red**: Extreme Danger (3+ levels above you)
  - **Orange**: Challenging
  - **Green**: Optimal (Peak XP and questing efficiency)
  - **Teal**: Slightly Low
  - **Grey**: Trivial / Low XP
- **Leveling Advisor Command (`/gf zones`)**: Prints an instant list of optimal leveling zones and dungeons matching your exact character level to chat.

### 7. 🔍 Universal Tooltip Classless Enhancer
- **Classless Metadata Injection**: Enhances standard game tooltips across the Spellbook, Action Bars, and Chat Links:
  - **Class of Origin**: Color-coded class badge (e.g. `[Warrior]`, `[Mage]`, `[Paladin]`).
  - **School & Role**: Magic school and category (e.g. `Fire • Ranged Spell`).
  - **Synergy Indicators**: Displays which combo archetypes the ability fuels.
  - **Equipment Warnings**: Instant warning if you lack the required weapon type (Shield, Dagger, Ranged weapon).

---

## 🛠️ Installation

1. Download or extract the `GrimfallHelper` folder.
2. Ensure the folder is named `GrimfallHelper`.
3. Place `GrimfallHelper` into your World of Warcraft AddOns directory:
   ```
   World of Warcraft/Interface/AddOns/GrimfallHelper/
   ```
4. Launch your **3.3.5a** client, verify GrimfallHelper is checked in your AddOns menu, and log in!

---

## ⌨️ Slash Commands

| Command | Action |
| :--- | :--- |
| `/gf` or `/grimfall` | Open / Toggle the Main Dashboard |
| `/gf send [player]` | Send your full build & runes directly to target player via whisper |
| `/gf shared` | Open Shared Builds inbox (received player builds) |
| `/gf share [party\|guild]` | Share your build summary to Party or Guild chat |
| `/gf export` | Open 1-Click Build Exporter & AI Markdown generator |
| `/gf spellbook` | Open Classless Spellbook browser |
| `/gf runes` | Search all 2,615 Grimfall Runes in the Rune List |
| `/gf zones` | Show recommended leveling zones and dungeons for your level |
| `/gf debugrunes` | Print local rune detection diagnostic information |
| `/gf help` | Display in-game slash command list |

---

## 🗺️ Minimap Controls

- **Left-Click**: Open / Toggle Main Dashboard.
- **Right-Click**: Open Shared Builds inbox directly.
- **Hover**: View tooltip with current archetype, build score, and active rune count.
- **Left-Click + Drag**: Freely reposition icon around the minimap border.

---

## 📦 Technical Specifications

- **Client Compatibility**: WoW 3.3.5a (Wrath of the Lich King, Interface 30300).
- **Dependencies**: **Zero** external libraries required. 100% native WoW Lua 5.1 code.
- **SavedVariables**:
  - `GrimfallHelperDB`: Global account preferences (window positions, minimap angle).
  - `GrimfallHelperCharDB`: Character-specific settings.
