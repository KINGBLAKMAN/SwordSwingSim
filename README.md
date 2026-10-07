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
2. Install [Rokit](https://github.com/rojo-rbx/rokit), then run `rokit install` in the repo. That installs the pinned Rojo, Wally, Selene, StyLua, Lune and luau-lsp from `rokit.toml`.
3. Run `wally install` to download packages into `Packages/` and `ServerPackages/`.
4. Run `rojo serve`, open Studio, and connect with the Rojo plugin.

## Layout

| Folder | Lands in Studio as | Holds |
| --- | --- | --- |
| `src/server` | ServerScriptService.Server | Entry script, `Services/` (TDD B2) and `Net/Remotes`. Owns RNG, damage and currencies. |
| `src/client` | StarterPlayerScripts.Client | Entry script, `Controllers/`, `UI/` (React-lua screens) and `Net/Remotes`. Renders and sends intent. |
| `src/shared` | ReplicatedStorage.Shared | `Bootstrap`, `Config/` (tuning tables, remote rate limits, asset registry), `Data/` (profile type and delta replication), `Net/` (remote schemas, validation, rate limiter), `Util/` (BigNum, Format, WeightedRandom). |
| `Packages/` | ReplicatedStorage.Packages | Wally shared packages: React, ReactRoblox, Signal, Trove. |
| `ServerPackages/` | ServerScriptService.ServerPackages | Wally server packages: ProfileStore. |

### Adding a remote

1. Add its schema to `src/shared/Net/RemoteSchemas.luau`, with a `Validate` check for every argument. Only send intent, never amounts, prices or outcomes.
2. For a `ToServer` remote, add its rate limit to `src/shared/Config/RemoteLimits.luau`. The server won't start without one.
3. On the server, call `Remotes.on("Name", handler)` in the service's `start()`. The handler only runs for calls that passed the rate limit and the argument checks. On the client, call `Remotes.fire("Name", ...)`.

### Changing player data

1. Add the field to `src/shared/Data/ProfileTypes.luau` and give it a starting value in `src/server/Services/DataService/ProfileTemplate.luau`. Reconcile copies it into existing saves.
2. If you renamed, moved or changed the type of a field, also add a step to `src/server/Services/DataService/Migrations.luau`. Never edit a step that has shipped.
3. In code, write with `DataService.set(player, path, value)` or `DataService.update(...)`, never straight into the profile table, so the client gets the change.

New services and controllers are added by hand to the list in their entry script, so startup order is explicit and fully typed.

## Checks

Run these before pushing; CI runs the same ones.

- Format: `stylua src tests` (CI uses `stylua --check src tests`)
- Lint: `selene src`
- Type check: `rojo sourcemap default.project.json -o sourcemap.json`, then `luau-lsp analyze --sourcemap=sourcemap.json --ignore="Packages/**" --ignore="ServerPackages/**" src`
- Unit tests: `lune run tests/run.luau` (pure-logic modules only; anything that needs Roblox APIs is tested in Studio)
- Build: `rojo build default.project.json -o SwordSwingSim.rbxl`

## CI and publishing

`.github/workflows/ci.yml` runs the checks and a Rojo build on every push and PR. Pushes to `main` publish to the Test place, and tags like `v1.2.0` publish to Prod. Publishing stays off until you add these in GitHub under Settings > Secrets and variables > Actions:

- Secret `ROBLOX_API_KEY`: an Open Cloud API key with Place Publishing write access for both universes.
- Variables `TEST_UNIVERSE_ID`, `TEST_PLACE_ID`, `PROD_UNIVERSE_ID`, `PROD_PLACE_ID`.
