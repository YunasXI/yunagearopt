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
| `/ygo lac` | Export the LuAshitacast profile for your main job |
| `/ygo gs` (or `gearswap`) | Export the GearSwap Lua for your main job |
| `/ygo equip [set]` | Equip the current (or named) set |
| `/ygo compact` | Toggle compact mode |
| `/ygo notice` | Show the notice again |
| `/ygo reload` | Reload data files |
| `/ygo debug <item>` | Dump how an owned item was parsed |

## Exports

- **LegacyAC** (Ashita): saved to `legacyac/CharacterName_JOB_YunaGearOpt.xml`, with a copy in `Ashita\config\LegacyAC\`. Load with `/la load CharacterName_JOB_YunaGearOpt.xml`.
- **LuAshitacast** (Ashita): saved to `lac/CharacterName_JOB.lua` and straight into `Ashita\config\addons\luashitacast\CharacterName_ID\JOB.lua` (an existing profile is backed up first as `JOB_backup_<date>.lua`). Load with `/lac load`. Toggles: `/lac fwd pdt`, `mdt`, `hybrid`, `mb`, `th`.
- **GearSwap** (Windower): saved to `gearswap/CharacterName_JOB.lua`. Copy it to `Windower\addons\GearSwap\data\`.

## Score and Best in Slot

Every set shows a score and how close it is to **Best in Slot** — the best gear for that job and set among every item in the game (up to level 75, `bis_level` in `data.lua`) plus your own augmented pieces:

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

Exports are git-ignored. Only gear in bags LegacyAC can equip from (Inventory and Wardrobes) is usable; the addon warns about pieces stored elsewhere.

## Files

| File | Purpose |
| --- | --- |
| `yunagearopt.lua` | Addon entry point, UI, set builder and exporters |
| `data.lua` | Item/stat data |
| `stats.lua` | Stat parsing |
| `augments.lua` | Augment parsing |

## Releases

Releases are created manually from the **Actions → Release** workflow. It bumps the version (patch by default; choose minor/major), tags it, and attaches `yunagearopt-<version>.zip`.
