# Dragoncraft — Session Handoff Document

> **Instructions for new Claude sessions:**
> Read this file at the start of every new conversation before giving any advice or writing any prompts.
> This document is the source of truth for project state. It is updated at the end of each conversation.
> The repo is at https://github.com/RogersJohn/DragonCraft — clone and review it when in doubt.

---

## Project Identity

| Field | Value |
|---|---|
| Game name | Dragoncraft |
| Repo | https://github.com/RogersJohn/DragonCraft |
| Engine | Godot 4.6.2 / GDScript only |
| Platform | Windows |
| Art style | Isometric medieval fantasy — Age of Empires II aesthetic |
| Starting village | **Minimap** (deliberately named — do not suggest changing it) |

**Team:**
- Father — experienced software developer, directs Claude Code, reviews all output
- Conor (son, age 9) — directs what to build, the target player

**Tone for Claude:** Zero sycophancy. Challenge weak decisions. Ask questions before writing code. Explain *why* decisions are made — Conor is learning. Flag token-heavy operations before doing them.

---

## Build State

### Phases

| Phase | Name | Status |
|---|---|---|
| 1 | Foundation — resource tick, village scene, HUD | ✅ Complete |
| 2 | Village life — buildings, seasons, people, save/load | ✅ Complete |
| 3 | Dragon core — eggs, explorer, incubation, hatching | ✅ Complete |
| 4 | World map development | 🔲 Not started |
| 5 | Polish — animations, audio, multi-village, tutorial | 🔲 Not started |

### What is working
- Title screen: logo, fade-in, **New Game** and **Continue** buttons
- New Game clears all saves and regenerates eggs
- World map with clickable Minimap village zone, cursor change on hover
- Village scene with background image and full HUD
- Four seasons (Spring/Summer/Autumn/Winter), 15 real minutes each, game always starts in Spring
- Game days: 2 real minutes per day, displayed in HUD
- Harvest bonuses on season change (data-driven from `seasons.json`)
- Winter locks population growth and halves tick rates
- Resources: Food, Gold, Wood, People — tick from JSON, displayed in HUD
- Five named villagers: Aldric, Brenna, Caelan, Dwyn, Eira — each a `Person` object with inventory
- Clickable houses: settler system costs 50 food, locked in Winter, unlocks at day 10
- Per-person inventory: 1 slot each, holds one dragon egg
- Explorer system: assign villager as explorer, they disappear from village UI, appear as a moving sprite on world map
- Explorer moves via WASD/arrow keys, constrained to 15% radius from village
- Explorer name displayed above sprite on world map
- 10 hidden dragon eggs per game, randomised placement respecting biome rules
- Egg discovery: "!" indicator at 150px, species revealed at 50px
- Pick up egg (goes to explorer inventory) or leave a 🚩 flag marker
- Species-coloured dot on map marks where egg was collected
- Explorer returns to village by clicking village icon on world map
- Dragon Training School: clickable in village, opens full-screen school panel
- School panel: 3 incubation nests, egg picker, 3-minute countdown (data-driven)
- Egg state art changes as incubation progresses (fresh → cracking → nearly hatched)
- Hatching reveals baby dragon with name and "Add to Village" button
- Hover over school building shows countdown tooltip for active nests
- Time controls: Pause / 1x / 5x / 10x — bottom-right, hidden on title screen
- Auto-save every 5 minutes (10 rotating slots), manual save F5
- Full save/load: resources, people, houses, seasons, incubation state, explorer position

---

## Architecture Rules (Non-Negotiable)

These must be followed in every session. If Claude Code violates them, write a fix prompt before continuing.

| Rule | Detail |
|---|---|
| Signals only | No direct cross-script calls between systems |
| Data-driven | All game values in `data/*.json` — never hardcode numbers in scripts |
| No `_process()` for timers | Always use Godot `Timer` nodes with `BASE_TICK / multiplier` pattern |
| Autoloads | Only: `SeasonManager`, `GameClock`, `TimeController`, `SaveManager` |
| Button styling | Always `UITheme.apply_gold_button()` — no inline `StyleBoxFlat` elsewhere |
| Script length | Max 200 lines — split if larger |
| Resource changes | `village.gd` is the single point of resource modification |
| Role changes | `PersonManager.set_role()` is the only way to change a person's role |
| Timer pattern | Store `const BASE_TICK: float = 1.0`, adjust via `_timer.wait_time = BASE_TICK / multiplier` |
| Auto-save timer | Must never be speed-scaled — explicitly excluded from `speed_changed` handler |

---

## Key Files Reference

```
scripts/main.gd                    Scene orchestrator, all transitions
scripts/village.gd                 Village simulation, resource tick, school zone
scripts/world_map.gd               World map, explorer movement, egg markers
scripts/season_manager.gd          AUTOLOAD — seasons and harvest
scripts/game_clock.gd              AUTOLOAD — day tracking
scripts/time_controller.gd         AUTOLOAD — speed multiplier and pause
scripts/save_manager.gd            AUTOLOAD — save/load all state
scripts/person.gd                  Person data class (extends RefCounted, not Node)
scripts/person_manager.gd          Manages all villagers
scripts/house_manager.gd           House occupancy and settler logic
scripts/egg_manager.gd             Egg placement, discovery, flags, pickup markers
scripts/incubation_manager.gd      Egg incubation slots, hatching
scripts/ui/ui_theme.gd             Static button styling — apply_gold_button()
scripts/ui/dragon_school_panel.gd  School menu UI — 3 nest slots
scripts/ui/house_popup.gd          House click menu with settler and person list
scripts/ui/inventory_panel.gd      Per-person inventory UI
scripts/ui/time_controls.gd        Pause/speed button bar
scripts/ui/egg_popup.gd            Egg discovery popup with species colour
data/resources.json                Resource tick rates and starting values
data/seasons.json                  Season durations, bonuses, tick multipliers
data/houses.json                   House config, settler cost (50), day unlock (10)
data/people.json                   Villager names, roles, starting assignments
data/eggs.json                     Generated at runtime, saved in user://saves/
data/dragons.json                  Dragon names, incubation_seconds (180), max_incubation_slots (3)
assets/images/logo.jpeg            Gold Dragoncraft logo — black background
assets/images/first_map.jpeg       World map — parchment style
assets/images/first_view_village.png  Village isometric art
assets/images/dragon_school_interior.png  School menu background
assets/images/egg_states.png       Three egg states in one image — crop with AtlasTexture
assets/images/hatchling_dragon.png Baby dragon — black background (known issue, see below)
```

---

## Known Issues

These are open and should be fixed before or during Phase 4. Do not re-implement — just fix.

| # | Issue | File | Priority |
|---|---|---|---|
| 1 | ~~Explorer name label stays at spawn position while explorer moves~~ | `world_map.gd` | ✅ Fixed — Session 16 |
| 2 | ~~`hatchling_dragon.png` has solid black background visible over school interior~~ | `dragon_school_panel.gd` | ✅ Fixed — Session 16 |
| 3 | Dragon roster is empty — "Add to Village" clears the nest but creates no dragon entity | `dragon_school_panel.gd` | Phase 4 blocker |
| 4 | Road constraints for explorer not implemented — moves freely within radius | `world_map.gd` | Deferred |
| 5 | Ocean egg flagged `requires_boat: true` — permanently unreachable | `egg_manager.gd` | Deferred — boats future phase |
| 6 | Specialised roles (Wizard, Trainer, etc.) exist in data but have no gameplay effect | `person_manager.gd` | Deferred |
| 7 | Trading houses, wizard school, animal pen not clickable | `village.gd` | Deferred |

---

## Phase 4 Scope (Not Started)

Agreed next phase. Do not start until Conor confirms priority order.

Options in rough priority order:
1. **Dragon entity system** — hatched dragons added to village roster with name, species, and attributes. Natural continuation of Phase 3.
2. **Other village buildings** — trading houses, wizard school, animal pen become interactive
3. **World map development** — fog of war, additional villages, zoom/pan improvements

**Before writing any Phase 4 prompts**, ask Conor which of these he wants first.

---

## Token Efficiency Rules

Follow these in every session to protect the Pro subscription budget.

- Do **not** run `/init` on the full directory — assets are large, it burns tokens scanning them
- For code reviews, clone the repo and read specific files — do not ask Claude Code to summarise everything
- Keep each Claude Code session to **one system, 5–9 files maximum**
- Do visual positioning (hitbox placement over art) in the **Godot editor directly** — not via Claude Code iteration
- Use **claude.ai chat** for design decisions and architecture — only open Claude Code to write files
- If context warning appears in Claude Code, run `/compact` immediately or start a new session
- Switch model to standard context (not 1M) unless the codebase is very large — standard is sufficient for current project size

---

## Session Prompts — Ready to Use

### Start of new claude.ai session
Paste this at the start of any new conversation:

```
I am building a game called Dragoncraft with my 9-year-old son Conor.
Read the HANDOFF.md file in the repo at https://github.com/RogersJohn/DragonCraft
before giving any advice. Clone the repo and check the current code state.
We are starting a new conversation — the previous one got too long.
The handoff document has full project context. Please confirm you have read it
and tell me the current build state before we proceed.
```

### Start of new Claude Code session
```
Read CLAUDE.md first. Then read HANDOFF.md.
Confirm current phase and list any known issues before we begin.
Do not write any code until I give you a specific task.
```

### Phase 4 planning session (first session of Phase 4)
```
Read CLAUDE.md and HANDOFF.md first. This is Phase 4 planning.
Do not write any code in this session.

Review these files only:
scripts/incubation_manager.gd
scripts/person.gd
scripts/person_manager.gd

Then answer:
1. What data does a hatched dragon need as a minimum viable entity?
2. Where should DragonManager live — who instantiates it?
3. What signal should IncubationManager emit that DragonManager listens to?
4. Which known issue from HANDOFF.md should be fixed before Phase 4 begins?

Do not propose implementation. Answer the questions only.
Wait for approval before suggesting anything further.
```

---

## Conversation History Summary

| Session | What was built |
|---|---|
| Session 1 | Project setup, GDD created, repo created, Godot installed |
| Session 2 | Title screen, world map, village scene, resource tick (Phase 1 complete) |
| Session 3 | Season system, harvest bonuses, HUD season display |
| Session 4 | People resource, house menus, settler system (Session B) |
| Session 5 | Save/load system, UITheme refactor, people type fix (Session C) |
| Session 6 | Day system, settler cost 50, 10-day house unlock (Session D) |
| Session 7 | Person class and PersonManager replacing people counter (Session E) |
| Session 8 | Per-person inventory panel, explorer role toggle (Session F) |
| Session 9 | Explorer sprite, egg discovery, pickup and flag system (Session G) |
| Session 10 | Various bug fixes: inventory default, UITheme zone, season layer, explorer snapshot |
| Session 11 | Flag emoji marker, species colours in popup, pickup dot, New Game vs Continue |
| Session 12 | Time controls — Pause/1x/5x/10x (persistent, speed-scales all timers) |
| Session 13 | Explorer visibility, village return, egg transfer, explorer name on map |
| Session 14 | Dragon school menu, incubation slots, hatching timer, hatchling reveal |
| Session 15 | Fix: incubation Timer node (was _process), config from dragons.json |
| Session 16 | Fix: explorer name label follows sprite (Issue #1), hatchling black background shader (Issue #2) |

---

## Art Assets Locked

These define the visual style. All new AI-generated art must match.

| Asset | Description | Status |
|---|---|---|
| `logo.jpeg` | Gold DRAGONCRAFT lettering, dragon forms the G, black background | ✅ Locked |
| `first_map.jpeg` | Parchment world map, illustrated medieval style | ✅ Locked |
| `first_view_village.png` | Isometric village, warm earthy palette | ✅ Locked |
| `dragon_school_interior.png` | Isometric school interior, 3 stone pedestals | ✅ Locked |
| `egg_states.png` | Three egg states on pedestals, green → cracking → bursting | ✅ Locked |
| `hatchling_dragon.png` | Baby green dragon, broken shell, black background | ✅ Locked |

**Art generation base prompt:**
> Isometric view, medieval fantasy game asset, same art style as Age of Empires II, warm earthy palette with greens and browns, painted texture, high detail, game asset quality, consistent 2:1 isometric angle.

---

*Last updated: End of Session 16 — Phase 3 complete, Issues #1 and #2 fixed, Phase 4 not started.*
*Update this document at the end of every conversation before closing.*
