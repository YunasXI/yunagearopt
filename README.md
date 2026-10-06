# YunaGearOpt

An [Ashita v4](https://www.ashitaxi.com/) addon that scans all the gear on your character and lets you build and tweak your favorite sets directly in-game. Based on item stats (augments included), it automatically picks everything you need for optimized sets, and with a single click exports a complete file for your job:

- **LegacyAC** XML (Ashita)
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
| `/ygo gs` (or `gearswap`) | Export the GearSwap Lua for your main job |
| `/ygo equip [set]` | Equip the current (or named) set |
| `/ygo compact` | Toggle compact mode |
| `/ygo notice` | Show the notice again |
| `/ygo reload` | Reload data files |
| `/ygo debug <item>` | Dump how an owned item was parsed |

## Exports

- **LegacyAC** (Ashita): saved to `legacyac/CharacterName_JOB_YunaGearOpt.xml`, with a copy in `Ashita\config\LegacyAC\`. Load with `/la load CharacterName_JOB_YunaGearOpt.xml`.
- **GearSwap** (Windower): saved to `gearswap/CharacterName_JOB.lua`. Copy it to `Windower\addons\GearSwap\data\`.

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
