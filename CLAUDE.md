# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dragoncraft** is a peaceful medieval fantasy village-building and dragon-nurturing strategy game built in **Godot 4 / GDScript**. The style is similar to Age of Empires II — top-down strategy with resource management and unit progression.

## Engine & Language

- Engine: Godot 4
- Language: GDScript
- No C# or GDNative — pure GDScript only

## Intended Project Structure

```
Dragoncraft/
├── project.godot
├── assets/
│   ├── images/          # ui/, buildings/, dragons/, eggs/, maps/
│   ├── audio/           # music/, sfx/
│   └── fonts/
├── data/                # JSON-driven game data (see Data Layer below)
│   ├── dragons.json
│   ├── buildings.json
│   ├── resources.json
│   └── training.json
├── scenes/              # .tscn scene files
│   ├── Main.tscn
│   ├── WorldMap.tscn
│   ├── Village.tscn
│   ├── Dragon.tscn
│   └── ui/              # HUD.tscn, DragonPanel.tscn, VillagePanel.tscn
└── scripts/             # .gd script files mirroring scenes/
    ├── main.gd
    ├── world_map.gd
    ├── village.gd
    ├── dragon.gd
    ├── resource_manager.gd
    ├── time_manager.gd
    ├── save_manager.gd
    └── ui/              # hud.gd, dragon_panel.gd, village_panel.gd
```

## Core Systems Architecture

### Data Layer (`data/*.json`)
Game definitions live in JSON, not hardcoded in scripts. Scripts load these at startup via `resource_manager.gd`. The four data files:
- `dragons.json` — dragon species definitions (stats, growth stages, abilities)
- `buildings.json` — building types, costs, production rates
- `resources.json` — resource types and tick rates
- `training.json` — training actions, durations, costs

### Key Scripts (intended roles)
- `main.gd` — scene bootstrapper, wires up global systems
- `resource_manager.gd` — loads JSON data, tracks player resources, emits signals on change
- `time_manager.gd` — game clock, tick system for resource/dragon growth loops
- `save_manager.gd` — serializes/deserializes game state to disk
- `village.gd` — manages buildings and villager simulation within a village node
- `world_map.gd` — top-level map, village selection, inter-village travel
- `dragon.gd` — dragon lifecycle: egg → hatchling → adult, stat tracking, bonding

### Signal Flow
Godot signals are the primary communication mechanism between systems. `resource_manager` and `time_manager` should emit signals consumed by UI and simulation scripts — avoid direct cross-script calls where possible.

### UI Pattern
UI scenes in `scenes/ui/` are driven by their paired scripts in `scripts/ui/`. They listen to signals from game systems rather than polling state each frame.

## Development Commands

Since this is a Godot 4 project, use the Godot editor or CLI:

```bash
# Run the project (headless, e.g. for CI or scripted export)
godot --headless --quit

# Export (requires export templates installed)
godot --export-release "Windows Desktop" build/DragonCraft.exe

# Run a specific scene
godot scenes/Main.tscn
```

For day-to-day development, open `project.godot` in the Godot 4 editor.

## Asset Notes

- `First View Village.png`, `first_map.jpeg`, `logo.jpeg` — concept art in the repo root, should be moved to `assets/images/` once the folder structure is created
- Do not commit Godot's `.godot/` cache folder (covered by .gitignore)
