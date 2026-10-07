# SwordSwingSim

An original anime sword simulator for Roblox: click to build Energy, cut through islands of escalating enemies, hatch original warrior-spirit pets, rebirth, repeat.

## Plan and docs

- **Full plan (GDD + TDD + art pipeline):** https://claude.ai/code/artifact/41374612-c464-44a1-af51-9f7f7e5c087d
- **Tuning sheet:** [`docs/Anime_Sword_Sim_Tuning.xlsx`](docs/Anime_Sword_Sim_Tuning.xlsx) — all balance numbers; config is generated from it.
- **Prompt library:** [`docs/prompts.md`](docs/prompts.md) — ready-to-paste prompts for every build step.

## Project rules

- Original IP only — no characters, names, symbols or techniques from existing series.
- Readable code over clever code. Optimize only what profiling shows is slow.
- Server-authoritative: the client sends intent; the server owns RNG, damage and currencies.
- Numbers live in config tables, never hardcoded.
- Stack: Rojo, Wally, Selene, StyLua, strict Luau, React-lua (UI), ProfileStore (saves).

## Workflow

- One branch per system (`feature/egg-service`), commit after each working step, merge once it's tested in Studio.
- Art lives in `art/` and goes through Git LFS (see `.gitattributes`). The `.blend` file is the source of truth — re-export, never hand-edit meshes in Studio.

## Setup

1. Install Git LFS once per computer, before cloning art: `git lfs install`.
2. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in the repo. That installs the pinned Rojo, Wally, Selene, StyLua and luau-lsp from `rokit.toml`.
3. Run `wally install` to download packages into `Packages/` and `ServerPackages/`.
4. Run `rojo serve`, open Studio, and connect with the Rojo plugin.

## Layout

| Folder | Lands in Studio as | Holds |
| --- | --- | --- |
| `src/server` | ServerScriptService.Server | Entry script and `Services/` (TDD B2). Owns RNG, damage and currencies. |
| `src/client` | StarterPlayerScripts.Client | Entry script, `Controllers/` and `UI/` (React-lua screens). Renders and sends intent. |
| `src/shared` | ReplicatedStorage.Shared | `Bootstrap`, `Config/` (generated tuning tables and the asset registry), `Util/`. |
| `Packages/` | ReplicatedStorage.Packages | Wally shared packages: React, ReactRoblox, Signal, Trove. |
| `ServerPackages/` | ServerScriptService.ServerPackages | Wally server packages: ProfileStore. |

New services and controllers are added by hand to the list in their entry script, so startup order is explicit and fully typed.

## Checks

Run these before pushing; CI runs the same ones.

- Format: `stylua src` (CI uses `stylua --check src`)
- Lint: `selene src`
- Type check: `rojo sourcemap default.project.json -o sourcemap.json`, then `luau-lsp analyze --sourcemap=sourcemap.json --ignore="Packages/**" --ignore="ServerPackages/**" src`
- Build: `rojo build default.project.json -o SwordSwingSim.rbxl`

## CI and publishing

`.github/workflows/ci.yml` runs the checks and a Rojo build on every push and PR. Pushes to `main` publish to the Test place, and tags like `v1.2.0` publish to Prod. Publishing stays off until you add these in GitHub under Settings > Secrets and variables > Actions:

- Secret `ROBLOX_API_KEY`: an Open Cloud API key with Place Publishing write access for both universes.
- Variables `TEST_UNIVERSE_ID`, `TEST_PLACE_ID`, `PROD_UNIVERSE_ID`, `PROD_PLACE_ID`.
