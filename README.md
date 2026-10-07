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

Git LFS must be installed before cloning art: `git lfs install`.
