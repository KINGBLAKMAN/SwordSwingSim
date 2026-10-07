# SwordSwingSim

Original anime sword simulator for Roblox. The full plan (GDD part A, TDD part B, art part E, build order part D) is in https://claude.ai/code/artifact/41374612-c464-44a1-af51-9f7f7e5c087d. Section numbers like B6 refer to it. Ready-made prompts per system are in `docs/prompts.md`; mark a prompt "done" there when its system merges.

## Rules

- Original IP only. Names come from the rosters in GDD A12a.
- Readable code over clever code (TDD B1): clear names, short functions, comments that explain why. Optimize only what profiling shows is slow.
- Server-authoritative (TDD B6–B7): the client sends intent only. The server owns RNG, damage, currencies, cooldowns and auto loops.
- Every `.luau` file starts with `--!strict`. UI is React-lua, saves are ProfileStore.
- Numbers live in config tables under `src/shared/Config`, never hardcoded. Asset IDs go through `Config/Assets.luau`. Balance numbers come from `docs/Anime_Sword_Sim_Tuning.xlsx`. Islands, Enemies, Eggs, Pets, Rebirth, Levels, Traits and Combat are generated from it and `docs/rosters.csv` by `python tools/gen_config.py`: edit the sheet or roster and re-run, never the generated files.

## Layout

- `src/server` → ServerScriptService.Server: `init.server.luau` lists services in startup order; `Services/`, `Net/Remotes`.
- `src/client` → StarterPlayerScripts.Client: `init.client.luau` lists controllers; `Controllers/`, `UI/`, `Net/Remotes`.
- `src/shared` → ReplicatedStorage.Shared: `Bootstrap` (init all, then start all), `Config/`, `Data/` (ProfileTypes, ProfileDelta), `Net/` (RemoteSchemas, Validate, RateLimiter), `Util/` (OddsCalculator, PaidRandomRules, BigNum...).
- `tests/` → Lune unit tests for pure modules. Add each new spec to `tests/run.luau`. Load modules that use `require(script...)` with `tests/support/RojoRequire`.

New service or controller: a module with optional `init()` and `start()`, added by hand to its entry script's list. Connect remotes in `start()`.

Player data: read with `DataService.get`, write only with `DataService.set` / `update` so the change reaches the client. A new profile field goes in `Shared/Data/ProfileTypes` and `DataService/ProfileTemplate`; a renamed, moved or retyped field, or a new field inside per-item records like pets, also needs a step in `DataService/Migrations`.

Odds and paid random items (TDD B11): egg odds shown to players and the server roll both come from `Util/OddsCalculator`. On the server, luck for a roll comes from `ComplianceService.luckFor` (drops paid luck for restricted players), and opening, selling luck or trading checks `ComplianceService` first.

New remote: schema in `Shared/Net/RemoteSchemas` (a `Validate` check per argument, intent only), rate limit in `Config/RemoteLimits` for `ToServer` remotes, then `Remotes.on` / `Remotes.fire`.

## Checks (CI runs the same)

```
stylua src tests
selene src
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --definitions=@roblox=globalTypes.d.luau --sourcemap=sourcemap.json --ignore="Packages/**" --ignore="ServerPackages/**" src
lune run tests/run.luau
rojo build default.project.json -o SwordSwingSim.rbxl
python3 tools/gen_config.py --check
```

## Workflow

One branch and PR per system (`feature/<system>`). Commit after each working step. Don't edit scripts inside Studio: Rojo syncs files into Studio, not back.

### Auto-merge

Claude may merge its own PRs without asking, when all of these hold:

- Claude opened the PR (never merge someone else's PR).
- CI is green on the latest commit and there is no merge conflict.
- No review thread is left unanswered and no change was requested.
- The "Pull now" message for the PR has been posted in its thread.

Merge with squash and delete the branch afterwards, then say in the thread that it merged. Never merge red or pending CI, and never bypass branch protection. If Jonah says to hold a PR, leave it for him to merge.
