# Anime Sword Simulator — Prompt Library

Copy a prompt, fill in the [brackets], and paste it into Claude Code (code, Blender, Studio) or into chat (planning, docs, balancing). Section numbers (A4, B6, E5…) point at the plan doc:
https://claude.ai/code/artifact/41374612-c464-44a1-af51-9f7f7e5c087d

## How to use these

- Start every Claude Code session with the **session starter** so Claude reads the plan and rules first.
- One prompt = one system. Build it, test it in Studio, commit, then move to the next.
- Paste errors, screenshots and playtest notes back in.
- Phase 2+ systems all use the **generic system prompt** with the section numbers filled in.

---

## Session starter (paste first, every session)

```
I'm building my Roblox anime sword simulator (repo: KINGBLAKMAN/SwordSwingSim).
The full plan is in this doc:
https://claude.ai/code/artifact/41374612-c464-44a1-af51-9f7f7e5c087d
The tuning numbers are in docs/Anime_Sword_Sim_Tuning.xlsx, and these
prompts are in docs/prompts.md.

Rules for this project:
- Original IP only (rosters in GDD A12a).
- Readable code over clever code (TDD B1 code style rule).
- Server-authoritative: the client only sends intent (TDD B6–B7).
- React-lua for UI, ProfileStore for saves, strict Luau.
- Numbers come from config tables, never hardcoded.

Today I'm working on: [system / asset].
Read the relevant sections first, give me a short plan, then build it.
```

---

## Phase 0 — Foundations

### Prepare the repo — done (Oct 6, 2026)

Already done: `.gitignore`, Git LFS (`.gitattributes`), README, and `docs/` are in the repo. Keep this prompt for reference if you ever set up a fresh repo.
```
My game's repo already exists: KINGBLAKMAN/SwordSwingSim. Clone it (or use
my local copy at [folder]) and get it ready: add a .gitignore for a Rojo project
(built place files, Packages/, sourcemap.json, Blender backups like
*.blend1) without removing anything already in it, set up Git LFS for
.blend, .fbx and texture files in art/, and commit and push that. Then
explain the simple workflow I should follow: a branch per system, commit
after each working step, merge when it's tested in Studio.
```

### Scaffold the repo — done (Oct 7, 2026)

Already done: Rokit, Wally, Selene, StyLua, strict Luau, the bootstrap and CI are in the repo. Keep this prompt for reference.
```
Use roblox-dev:setup to scaffold the project in [folder]. Use the folder
layout from TDD B1. Wally packages: ProfileStore, jsdotlua/react,
jsdotlua/react-roblox, a Signal library and Trove. Add Selene, StyLua,
strict Luau and the GitHub Actions pipeline from B14. Explain each
config file in a sentence when you're done.
```

### Connect Studio MCP
```
Help me connect Roblox Studio's built-in MCP server to Claude Code, then
verify it by listing the children of Workspace in my open place.
```

### Bootstrap and remotes — done (Oct 7, 2026)

Already done: Init/Start bootstrap, Remotes with schemas, validation and per-remote rate limits, and Lune tests for the rate limiter. Keep this prompt for reference.
```
Build the server and client bootstrap (Init all services, then Start all)
and the Remotes module from TDD B6: typed schemas, per-remote rate limits,
argument validation. Write tests for the rate limiter.
```

### Core utilities
```
Build BigNum, Format and WeightedRandom in src/shared/Util per TDD B5 and
GDD A4 (suffix list K, M, B ... then 1.23e123). Include tests, including a
chi-squared check on WeightedRandom over 1,000,000 rolls.
```

### Save system
```
Build DataService per TDD B3–B4 with ProfileStore: the Profile type,
schemaVersion migrations, Reconcile, a safe path when data fails to load
(C7: never play on a blank profile), and ProfileDelta replication to the
client.
```

### Compliance and odds
```
Build ComplianceService and the shared OddsCalculator per TDD B11. The same
OddsCalculator must produce both the odds shown in UI and the server roll.
Add tests that every egg sums to 100% and that restricted players can't
reach paid-random items.
```

### UI shell
```
Build the React-lua UI shell per TDD B9: a screen router, the HUD (currency
chips, level bar, Click! button, menu rail) and the component kit (Button,
CurrencyChip, RarityFrame, ProgressBar, TimerChip, ItemCard, ConfirmDialog).
Mobile-first scaling with safe-area insets and 44px touch targets.
```

### Config pipeline
```
Write a script that reads docs/Anime_Sword_Sim_Tuning.xlsx (or CSV exports of
its tabs) and generates Luau config modules in src/shared/Config: Islands,
Enemies, Eggs, Pets, Rebirth, Levels, Traits. Use the rosters in GDD A12a
for names. Re-running it after I change the sheet should update everything.
```

---

## Phase 1 — MVP (island 1)

Run these in order.

1. **Click and Energy**
   ```
   Build ClickService and server-side auto-click per GDD A10 and TDD B6–B7.
   ```
2. **Enemies and combat**
   ```
   Build EnemyService and CombatService for island 1 per GDD A9 and A12a:
   spawning, pooling, HP bars, damage numbers, shared kill credit.
   ```
3. **Drops**
   ```
   Build DropService per GDD A9: rolled and granted drop tables, pet drops at
   12.5–15%, and an enemy info panel showing the full table.
   ```
4. **Egg**
   ```
   Build EggService and the egg UI per GDD A6: Open, odds panel with a
   Details button, server roll through OddsCalculator, hatch animation with
   skip.
   ```
5. **Pets**
   ```
   Build PetService per GDD A7: inventory, equip, Equip Best, locks, and
   client-only pet following per TDD B8.
   ```
6. **Quests**
   ```
   Build QuestService with island 1's quest chain per GDD A13.
   ```
7. **First purchase**
   ```
   Add the x2 Coins game pass and the ProcessReceipt flow per TDD B10, with
   the idempotency test.
   ```
8. **Island 2 gate**
   ```
   Add island 2's unlock, requirement and teleport per GDD A12.
   ```
9. **MVP check**
   ```
   Write a playtest checklist from the D2 exit criteria and walk me through
   testing it in Studio.
   ```

---

## Phase 2+ — generic system prompt

```
Build [system] from GDD [section] and TDD [section]. Use
roblox-dev:new-system. Pull all numbers from config. Validate every remote
on the server. Write tests for the pure logic. When you're done, list what
you built and exactly what I should test in Studio.
```

| System | GDD | TDD |
| --- | --- | --- |
| Autos (click, open, delete) | A10, A15 | B6, B8 |
| Pity | A6 | B11 |
| Boosts and potions | A14 | B2 |
| Level and EXP | A4 | B2 |
| Rank Up | A4 | B2 |
| Rebirth and shop | A4 | B2 |
| Weapons and merges | A8 | B3 |
| Traits and rerolls | A11 | B3, B11 |
| Index | A7 | B3 |
| Daily, playtime, group rewards, codes | A13, A19 | B13 |
| Full Store | A17 | B10, B11 |
| Leaderboards | A18 | B4, B5 |
| Offline income and Auto Train | A10 | B2 |
| Stats and Logs | A22 | B2 |
| Server luck and friend boost | A14 | B11 |
| Battlepass | A16 | B10 |
| Raids and Time Trials | A20 | B2 |
| Trading | A21 | B7, B11 |

---

## Art — Blender

### Template (do once)
```
In Blender, build the scale-reference template from Part E: a 5-stud
Roblox character dummy, scene units for Roblox, the FBX export settings
from E5, and a script that checks triangle count against the E4 budgets,
UVs inside 0–1, and naming. Save it to [folder]/art/_template.blend.
```

### Character concept, then blockout
```
Write a concept sheet for [character] from GDD A12a: silhouette, key
shapes, palette with hex codes, what makes it clearly original, and its
E4 triangle budget. Then block it out in Blender with primitives and show
me a screenshot.
```

### Pet model
```
Model [pet] low-poly in Blender, under 1,500 triangles including the
outline shell (E2). Go blockout → refine → outline shell → UV unwrap, and
screenshot after each stage so I can steer before you continue.
```

### Swords
```
Model [sword] in Blender per E4 (300–1,500 tris), then write a bpy script
that generates blade and guard variants from it so I can make the
rest of the island's swords fast.
```

### Island props kit
```
Build a modular prop kit for [island] in Blender: [list props]. Share one
1024 texture atlas, keep each prop within E4 budgets, and lay them out on
a grid so I can review them in one screenshot.
```

### Rig and animate
```
Rig [enemy] on an R15-compatible skeleton per E6, then animate idle, hit
react and death per E7. Export one FBX per animation and tell me how to
import each through Studio's Animation Editor.
```

### VFX assets
```
Make the VFX assets for [effect] from the E8 table: [slash mesh / ring
mesh / 4x4 flipbook]. Render flipbooks with transparent spacing between
frames, and keep meshes under 500 tris.
```

### Export to Studio
```
Export [asset] with the E5 settings, import it into Studio through Studio
MCP, check its scale and triangle count, save it as a template in
ReplicatedStorage and register its ID in Assets.luau (E9).
```

### Art review
```
Take a screenshot of [asset] in Blender and critique it: topology,
proportions, silhouette, and whether it reads at mobile camera distance.
Also check it against the A24 silhouette test.
```

---

## VFX in Studio

```
Build the [moment] effect from the E8 table in Studio, using [particles /
trail / beam / mesh]. Make rarity-colored presets, pool the instances, add
a low-graphics version, and put it in a VFX test place where I can trigger
each variant.
```

---

## Balancing

```
Here are my playtest results: [time on island X, kills, eggs opened,
rebirths, where it felt slow or fast]. Compare them to the tuning sheet
and tell me which inputs to change and by how much.
```

```
Update the tuning sheet: [change]. Recalculate and show me which islands
go off pace.
```

---

## Review and debugging

```
Use roblox-dev:review on [system or folder]. Fix the high-severity issues
and list the rest for me.
```

```
Here's an error from Studio: [paste the error and what I did]. Use
engineering:debug to find the cause, fix it, and tell me how to confirm
the fix.
```

```
Before I publish: go through the C6 compliance checklist against the
code and the Store, and list anything that isn't done.
```

---

## Planning and docs (in chat)

```
Add [feature] to the plan doc: where it fits in the GDD and TDD, what it
changes in the checklist and build order.
```

```
Draft Robux prices for every product in C5 using the A17 price ladder.
```

```
Give me 10 name options for the game that fit an original anime sword
simulator.
```
