# YunaGearOpt

An [Ashita v4](https://www.ashitaxi.com/) addon that scans all the gear on your character and lets you build and tweak your favorite sets directly in-game. Based on item stats (augments included), it automatically picks everything you need for optimized sets, and with a single click exports a complete file for your job:

- **LegacyAC** XML (Ashita)
- **LuAshitacast (LAC)** Lua (Ashita)
- **GearSwap** Lua (Windower)

## Installation

1. Download the latest `yunagearopt-x.y.z.zip` from [Releases](../../releases).
2. Extract it so you have `Ashita\addons\yunagearopt\`.
3. In game: `/addon load yunagearopt` (or add it to your default script).

## Usage

Commands (`/ygo` or `/yunagearopt`):

| Command | Description |
| --- | --- |
| `/ygo` | Toggle the window (rescans your gear) |
| `/ygo scan` | Rescan your bags |
| `/ygo export` (or `xml`) | Export the LegacyAC XML for your main job |
| `/ygo warp` | Warp: uses a Scroll of Instant Warp if you have one, otherwise equips and uses your Warp Ring |
| `/ygo lac` | Export the LuAshitacast profile for your main job |
| `/ygo gs` (or `gearswap`) | Export the GearSwap Lua for your main job |
| `/ygo equip [set]` | Equip the current (or named) set |
| `/ygo compact` | Toggle compact mode |
| `/ygo update` | Check GitHub for a new version now (and open the download page if there is one) |
| `/ygo notice` | Show the notice again |
| `/ygo reload` | Reload data files |
| `/ygo debug <item>` | Dump how an owned item was parsed |

## Exports

Every export first opens a **Before you export** window. It lists exactly which files will be written (in red if one already exists and will be replaced) and lets you **Back up & export** (each existing file is kept as `NAME_backup_<date>` in the same folder), export without a backup, or cancel.

- **LegacyAC** (Ashita): saved to `legacyac/CharacterName_JOB.xml`, with a copy in `Ashita\config\LegacyAC\`. Load with `/la load CharacterName_JOB.xml`.
- **LuAshitacast** (Ashita): saved to `lac/CharacterName_JOB.lua` and straight into `Ashita\config\addons\luashitacast\CharacterName_ID\JOB.lua` (an existing profile is backed up first as `JOB_backup_<date>.lua`). Load with `/lac load`. Toggles: `/lac fwd pdt`, `mdt`, `hybrid`, `mb`, `th`.
- **GearSwap** (Windower): saved to `gearswap/CharacterName_JOB.lua`. Copy it to `Windower\addons\GearSwap\data\`.

## Score and Best in Slot

Every set shows a score and how close it is to **Best in Slot** — the best gear for that job and set among the reference items (up to level 75, `bis_level` in `data.lua`). It is the same for everyone: your own pieces and their augments are not used for it, so your own set can even score above it:

- **Orange**: 90%+ of BiS (BiS / very good)
- **Yellow**: 70–89% (good)
- **Blue**: under 70% (medium, room to improve)

Each slot card shows its BiS piece (orange when you already own it); hover it for its stats. The BiS list is built in the background the first time you open the window.

### Best in Slot reference sets (`bis.lua`)

`bis.lua` holds hand-picked BiS sets taken from real CatsEyeXI XMLs (WAR, SAM, RDM, RNG, SCH, WHM, BRD, COR).
They are shown as the BiS for each set — in the ▼ dropdown and with **VIEW BIS SET** — even if you don't own the
pieces. Slots they don't list fall back to the automatic BiS. Add or edit sets there the same way.

### SCNM / Summit gear

Every job has a **2-hour set** with its Summit family (Apogee / Pinnacle / Apex — the 5-piece bonus is
*SP ability delay -5 min*), equipped when you use your 2-hour in all three exports. Apex Haidate (song duration)
and Apex Sune-Ate (song recast) are preferred for BRD songs, Apex Haidate (Phantom Roll +1) for COR rolls,
Pinnacle pieces for Berserk / Warcry / Meditate. Families and 2-hours are in `data.lua` (`summit`, `sp_abilities`).

Every export also has a **`/warp`** command (XML and LAC call `/ygo warp`, so keep YunaGearOpt loaded; the GearSwap file does it by itself), and puts your **Movement** set on while you run.

### More sets and rules

- **MNK**: Idle / PDT BiS, **Boost** (Temple Gloves +1, worn when you use Boost), **Chakra**, and **Counterstance**,
  which is worn on top of your engaged gear (TP, Hybrid, PDT, MDT) while the buff is up and comes off when you disengage.
- **BLU**: Physical / Magical / Debuff blue magic, Spectral Floe, Battery Charge and a **Refresh** idle set you switch on
  with `/refresh` (`//gs c refresh` in GearSwap, `/lac fwd refresh` in LAC). Melee sets keep your sword and shield after casting.
- **Artifact +1 / Relic +1**: 236 pieces are in the Best in Slot list with their max CatsEyeXI augment
  (Artifact Tier 3, Relic Rank 10 - `max_augments` in `data.lua`).
- **NIN**: Yoru Shuriken stays in the ammo slot in every set except weaponskills, which use Yetshila +1 (DEX) or
  Cinderstone (STR). **BRD**: one instrument (Gjallarhorn) in every set, so TP is never lost.
- **Adept Reforging**: all 69 Adept pieces (BLM, BRD, BST, DRG, DRK, GEO, NIN, PLD, RDM, RUN, SAM, THF, WAR, WHM) are in the
  Best in Slot list with their **full augment** (Tier 3, HQ), each only for its own job (`adept_augments` in `data.lua`).
- **PLD**: every spell puts on a **SIR** (spell interruption) set first, then **Flash**, **Reprisal** or **Phalanx** sets on top;
  every job ability puts on **Enmity** first, then its own piece (**Sentinel**, **Shield Bash / Chivalry**, **Rampart**, **Cover**);
  plus a Cure precast set. **Phalanx received**: when someone starts casting Phalanx on you (Phalanx II on you, or Phalanx from a
  party member), King's Cuisses / Phalanx-received gear goes on for 5-8 seconds - built into the LAC and GearSwap files, and for
  LegacyAC the addon does it with `/la set` (keep YunaGearOpt loaded).
- **DRG**: Jump / High Jump, Angon, Dragon Breaker, Ancient Circle, wyvern breath sets (a trigger piece on precast for
  Dia / Poison / Foot Kick / Barfire, a potency piece while the wyvern breathes), a Haste precast set that also covers
  Utsusemi, and Desert Boots while you run in earth weather.
- **Jailer torques** (Love, Prudence, Justice, Hope, Fortitude, Temp., Faith) are scored with their weapon skill bonuses
  for the weapon types your job uses.
- **BLU / WAR dual-wield weapons**: type **`/dw`** to toggle your dual-wield weapons on top of whatever set is active
  (BLU: Undulant Black + Blurred Rod +1, WAR: Brilliance + Blurred Rod +1). Type it again to switch back.
  GearSwap also accepts `//gs c dw`, LAC `/lac fwd dw`.
- **PUP**: automaton Tank and Ranged sets, Pummel (Stringing Pummel), TP, and the attachment list.
- **RNG / COR**: the BiS ranged weapons (Tonzoffun, Annihilator, Death Penalty) are used in ranged weaponskills,
  Preshot / Midshot and Quick Draw, and only if you own them. RNG has bow and gun versions of Preshot / Midshot, chosen by the
  weapon you are holding (`eq_range` in LegacyAC).
- **RDM**: BiS from your LuAshitacast profile, including the TP and dual-wield sets with their weapons.
- Crafting and synergy gear (Weaver's / Tanner's cuffs, smocks, aprons...) is ignored everywhere.
- Your explicit rules in `data.lua` (`preferred`) always beat the BiS reference, in your set and in the BiS view.

Exports are git-ignored. Only gear in bags LegacyAC can equip from (Inventory and Wardrobes) is usable; the addon warns about pieces stored elsewhere.

## Files

| File | Purpose |
| --- | --- |
| `yunagearopt.lua` | Addon entry point, UI, set builder and exporters |
| `data.lua` | Item/stat data |
| `stats.lua` | Stat parsing |
| `augments.lua` | Augment parsing |
| `server_stats.lua` | Real base stats per item from the CatsEyeXI server, used before reading item descriptions |

## Releases

Releases are created manually from the **Actions → Release** workflow. It bumps the version (patch by default; choose minor/major), tags it, and attaches `yunagearopt-<version>.zip`.
