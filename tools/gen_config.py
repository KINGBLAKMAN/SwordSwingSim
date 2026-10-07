#!/usr/bin/env python3
"""Generate Luau config modules from the tuning sheet and the GDD rosters.

Reads:
  docs/Anime_Sword_Sim_Tuning.xlsx  the numbers (or a folder of CSV exports
                                    of its tabs, with --csv)
  docs/rosters.csv                  the names from GDD A12a: one row per
                                    character, which is both a pet in its
                                    island's egg and an enemy on that island

Writes these modules in src/shared/Config (each says it is generated):
  Islands, Enemies, Eggs, Pets, Rebirth, Levels, Traits, Combat

Usage (from the repo root):
  python tools/gen_config.py               regenerate the config modules
  python tools/gen_config.py --check       fail if they don't match the sheet
  python tools/gen_config.py --csv DIR     read "<Tab name>.csv" files from DIR

Only Python 3's standard library is used, so there is nothing to install.

The script reads values the sheet already computed (Excel saves them with
the workbook), so changing a formula in the sheet flows through too. The
game recomputes rebirth and level curves from their parameters, so for
those the script also checks that the parameters reproduce the sheet's
tables and stops if they don't.

Values are found by their labels ("HP_BASE", "Base weight", ...), not by
cell address, so adding rows or columns to the sheet doesn't break it.
"""

from __future__ import annotations

import argparse
import csv
import math
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SHEET = REPO_ROOT / "docs" / "Anime_Sword_Sim_Tuning.xlsx"
DEFAULT_ROSTER = REPO_ROOT / "docs" / "rosters.csv"
CONFIG_DIR = REPO_ROOT / "src" / "shared" / "Config"

TAB_NAMES = ["Inputs", "Enemies", "Rebirth", "Island Pacing", "Egg Odds", "Traits", "Levels"]

# GDD A6: pity guarantees "Legendary or better". The sheet's Egg Odds tab
# states this in its text, not in a cell, so it lives here.
PITY_MIN_RARITY = "Legendary"

# The Rebirth tab's formula gives the kicker once per 10 rebirths
# (REBIRTH_KICKER^INT(r/10)). check_rebirth() stops if that changes.
REBIRTH_KICKER_EVERY = 10

# Inputs-tab levers that go into Config/Combat, by their name there. The
# sheet uses short names; the game spells them out.
COMBAT_LEVERS = {
    "BASE_ENERGY_PER_CLICK": "BASE_EPC",
    "START_ENERGY": "START_ENERGY",
    "DAMAGE_PER_ENERGY": "DPE",
    "SWING_RATE": "SWING_RATE",
    "CRIT_CHANCE": "CRIT_CHANCE",
    "CRIT_MULT": "CRIT_MULT",
}

# Island Coins pay for eggs and unlocks (GDD A5).
COINS = "coins"


class SheetError(Exception):
    """The sheet or roster is missing something the generator needs."""


# ---------------------------------------------------------------------------
# Reading the sheet into grids (a list of rows, each a list of cell values)
# ---------------------------------------------------------------------------

Grid = list[list[object]]

XLSX_NS = {
    "main": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "rel": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
    "pkgrel": "http://schemas.openxmlformats.org/package/2006/relationships",
}


def parse_number(text: str) -> object:
    """Turn "25" into 25, "2.5" into 2.5 and leave other text alone."""
    cleaned = text.strip().replace(",", "")
    try:
        number = float(cleaned)
    except ValueError:
        return text.strip() or None
    if number.is_integer() and abs(number) < 2**53:
        return int(number)
    return number


def column_index(cell_ref: str) -> int:
    """'B5' -> 1 (zero-based column)."""
    letters = re.match(r"[A-Z]+", cell_ref).group(0)
    index = 0
    for letter in letters:
        index = index * 26 + (ord(letter) - ord("A") + 1)
    return index - 1


def row_index(cell_ref: str) -> int:
    """'B5' -> 4 (zero-based row)."""
    return int(re.search(r"\d+", cell_ref).group(0)) - 1


def read_xlsx(path: Path) -> dict[str, Grid]:
    with zipfile.ZipFile(path) as archive:
        shared_strings = read_shared_strings(archive)
        grids = {}
        for name, sheet_path in sheet_paths(archive).items():
            grids[name] = read_xlsx_sheet(archive, sheet_path, shared_strings)
        return grids


def read_shared_strings(archive: zipfile.ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in archive.namelist():
        return []
    root = ET.fromstring(archive.read("xl/sharedStrings.xml"))
    strings = []
    for item in root.findall("main:si", XLSX_NS):
        # Rich text splits a string into runs; join every <t> inside it.
        strings.append("".join(t.text or "" for t in item.iter(f"{{{XLSX_NS['main']}}}t")))
    return strings


def sheet_paths(archive: zipfile.ZipFile) -> dict[str, str]:
    """Tab name -> path of its XML file inside the workbook."""
    workbook = ET.fromstring(archive.read("xl/workbook.xml"))
    rels = ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
    targets = {rel.get("Id"): rel.get("Target") for rel in rels.findall("pkgrel:Relationship", XLSX_NS)}
    paths = {}
    for sheet in workbook.find("main:sheets", XLSX_NS):
        target = targets[sheet.get(f"{{{XLSX_NS['rel']}}}id")]
        paths[sheet.get("name")] = target.lstrip("/") if target.startswith("/") else f"xl/{target}"
    return paths


def read_xlsx_sheet(archive: zipfile.ZipFile, sheet_path: str, shared_strings: list[str]) -> Grid:
    root = ET.fromstring(archive.read(sheet_path))
    grid: Grid = []
    for cell in root.iter(f"{{{XLSX_NS['main']}}}c"):
        ref = cell.get("r")
        row, col = row_index(ref), column_index(ref)
        while len(grid) <= row:
            grid.append([])
        while len(grid[row]) <= col:
            grid[row].append(None)
        grid[row][col] = xlsx_cell_value(cell, shared_strings)
    return grid


def xlsx_cell_value(cell: ET.Element, shared_strings: list[str]) -> object:
    cell_type = cell.get("t")
    if cell_type == "inlineStr":
        return "".join(t.text or "" for t in cell.iter(f"{{{XLSX_NS['main']}}}t")) or None
    # <v> holds the value; for a formula cell it's the result Excel saved.
    value = cell.find("main:v", XLSX_NS)
    if value is None or value.text is None:
        return None
    if cell_type == "s":
        return shared_strings[int(value.text)]
    if cell_type in ("str", "e"):
        return value.text
    if cell_type == "b":
        return value.text == "1"
    return parse_number(value.text)


def read_csv_folder(folder: Path) -> dict[str, Grid]:
    """Read one CSV per tab. A file counts for a tab when its name ends with
    the tab name, so "Island Pacing.csv" and "Tuning - Island Pacing.csv"
    both work."""
    grids = {}
    for tab in TAB_NAMES:
        matches = [p for p in folder.glob("*.csv") if p.stem.endswith(tab)]
        if not matches:
            continue
        with open(matches[0], newline="", encoding="utf-8-sig") as handle:
            grids[tab] = [[parse_number(text) for text in row] for row in csv.reader(handle)]
    return grids


# ---------------------------------------------------------------------------
# Finding values in a grid by their labels
# ---------------------------------------------------------------------------


def cell(grid: Grid, row: int, col: int) -> object:
    if row < len(grid) and col < len(grid[row]):
        return grid[row][col]
    return None


def find_label(grid: Grid, label: str, tab: str, after_row: int = -1) -> tuple[int, int]:
    """Position of the first cell whose text is `label`, below `after_row`."""
    for row in range(after_row + 1, len(grid)):
        for col, value in enumerate(grid[row]):
            if isinstance(value, str) and value.strip() == label:
                return row, col
    raise SheetError(f'{tab} tab: no cell labelled "{label}"')


def value_right_of(grid: Grid, label: str, tab: str) -> object:
    """The value next to a label, like Inputs!B5 next to "HP_BASE"."""
    row, col = find_label(grid, label, tab)
    value = cell(grid, row, col + 1)
    if value is None:
        raise SheetError(
            f'{tab} tab: "{label}" has no value. If it is a formula, open the '
            "sheet in Excel and save it so the result is stored."
        )
    return value


def number_right_of(grid: Grid, label: str, tab: str) -> float:
    value = value_right_of(grid, label, tab)
    if not isinstance(value, (int, float)):
        raise SheetError(f'{tab} tab: "{label}" should be a number, found {value!r}')
    return value


def read_table(grid: Grid, headers: list[str], tab: str, after_row: int = -1) -> list[dict]:
    """Rows under a header row, as dicts keyed by header.

    The header row is found by its first header; the others must sit in the
    same row. Reading stops at the first row where any column is blank, which
    is where the sheet's tables end (a total, a note or an empty row)."""
    row, first_col = find_label(grid, headers[0], tab, after_row)
    columns = {}
    for header in headers:
        for col in range(first_col, len(grid[row])):
            value = grid[row][col]
            if isinstance(value, str) and value.strip() == header:
                columns[header] = col
                break
        else:
            raise SheetError(f'{tab} tab: no "{header}" column next to "{headers[0]}"')

    rows = []
    for data_row in range(row + 1, len(grid)):
        values = {header: cell(grid, data_row, col) for header, col in columns.items()}
        if any(value is None for value in values.values()):
            break
        rows.append(values)
    if not rows:
        raise SheetError(f'{tab} tab: the "{headers[0]}" table has no rows')
    return rows


def require_tab(grids: dict[str, Grid], tab: str) -> Grid:
    if tab not in grids:
        raise SheetError(f'the sheet has no "{tab}" tab (or no "{tab}.csv" export)')
    return grids[tab]


# ---------------------------------------------------------------------------
# Pulling the game's numbers out of the sheet
# ---------------------------------------------------------------------------


def load_tuning(grids: dict[str, Grid]) -> dict:
    inputs = require_tab(grids, "Inputs")
    tuning = {
        "tiers": [row["Tier"] for row in read_table(inputs, ["Tier", "HP mult"], "Inputs")],
        "rarityFactor": {
            row["Rarity"]: row["Pet factor"] for row in read_table(inputs, ["Rarity", "Pet factor"], "Inputs")
        },
        "petBaseBonus": number_right_of(inputs, "PET_BASE_BONUS", "Inputs"),
        "petGrowth": number_right_of(inputs, "PET_GROWTH", "Inputs"),
        "levels": {
            "LEVEL_EXP_BASE": number_right_of(inputs, "LEVEL_EXP_BASE", "Inputs"),
            "LEVEL_EXP_EXP": number_right_of(inputs, "LEVEL_EXP_EXP", "Inputs"),
        },
        # Sheet lever name -> name in Config/Combat.
        "combat": {
            name: number_right_of(inputs, lever, "Inputs") for name, lever in COMBAT_LEVERS.items()
        },
        "rebirth": {
            "COST_BASE": number_right_of(inputs, "REBIRTH_COST_BASE", "Inputs"),
            "COST_GROWTH": number_right_of(inputs, "REBIRTH_COST_GROWTH", "Inputs"),
            "STEP": number_right_of(inputs, "REBIRTH_STEP", "Inputs"),
            "KICKER": number_right_of(inputs, "REBIRTH_KICKER", "Inputs"),
            "KICKER_EVERY": REBIRTH_KICKER_EVERY,
        },
    }
    tuning["enemyStats"] = load_enemy_stats(require_tab(grids, "Enemies"), tuning["tiers"])
    tuning["islands"] = load_island_pacing(require_tab(grids, "Island Pacing"))
    tuning["eggOdds"] = load_egg_odds(require_tab(grids, "Egg Odds"))
    tuning["traits"] = load_traits(require_tab(grids, "Traits"))
    check_rebirth(require_tab(grids, "Rebirth"), tuning["rebirth"])
    check_levels(require_tab(grids, "Levels"), tuning["levels"])
    return tuning


def load_enemy_stats(grid: Grid, tiers: list[str]) -> dict:
    """{island number: {tier: {"hp", "coins", "exp"}}} from the Enemies tab's
    three tables, each titled in the cell above its header row."""
    stats: dict = {}
    for title, stat in (("HP", "hp"), ("Coins per kill", "coins"), ("EXP per kill", "exp")):
        title_row, _ = find_label(grid, title, "Enemies")
        for row in read_table(grid, ["Island", *tiers], "Enemies", after_row=title_row):
            for tier in tiers:
                stats.setdefault(int(row["Island"]), {}).setdefault(tier, {})[stat] = row[tier]
    return stats


def load_island_pacing(grid: Grid) -> dict:
    """{island number: {"theme", "eggCost", "nextUnlockCost"}}."""
    headers = ["Island", "Theme (original)", "Egg cost", "Next island unlock cost"]
    islands = {}
    for row in read_table(grid, headers, "Island Pacing"):
        islands[int(row["Island"])] = {
            "theme": row["Theme (original)"],
            "eggCost": row["Egg cost"],
            "nextUnlockCost": row["Next island unlock cost"],
        }
    return islands


def load_egg_odds(grid: Grid) -> dict:
    rows = read_table(grid, ["Rarity", "Base weight", "Luck sensitivity"], "Egg Odds")
    return {
        "weights": {row["Rarity"]: row["Base weight"] for row in rows},
        "pityThreshold": number_right_of(grid, "Pity threshold", "Egg Odds"),
    }


def load_traits(grid: Grid) -> dict:
    rows = read_table(grid, ["Tier", "Weight"], "Traits")
    return {
        "order": [row["Tier"] for row in rows],
        "weights": {row["Tier"]: row["Weight"] for row in rows},
        "hardPity": number_right_of(grid, "Hard pity (rerolls)", "Traits"),
    }


def close_enough(a: float, b: float) -> bool:
    return abs(a - b) <= 1e-9 * max(1.0, abs(a), abs(b))


def check_rebirth(grid: Grid, rebirth: dict) -> None:
    """The game computes rebirth costs from the parameters (like Util/LevelCurve
    does for levels), so they must reproduce the Rebirth tab exactly."""
    headers = ["Rebirths owned (r)", "Energy cost of next rebirth", "Multiplier at r"]
    for row in read_table(grid, headers, "Rebirth"):
        r = int(row["Rebirths owned (r)"])
        cost = rebirth["COST_BASE"] * rebirth["COST_GROWTH"] ** r
        mult = (1 + rebirth["STEP"] * r) * rebirth["KICKER"] ** (r // rebirth["KICKER_EVERY"])
        if not (close_enough(cost, row[headers[1]]) and close_enough(mult, row[headers[2]])):
            raise SheetError(
                f"Rebirth tab, r = {r}: the sheet says cost {row[headers[1]]}, multiplier "
                f"{row[headers[2]]}, but the formula in tools/gen_config.py gives {cost}, {mult}. "
                "If the sheet's rebirth formula changed, update check_rebirth and the game's "
                "rebirth math to match."
            )


def check_levels(grid: Grid, levels: dict) -> None:
    """Util/LevelCurve computes EXP from the parameters; make sure they match
    the Levels tab."""
    for row in read_table(grid, ["Level", "EXP to next"], "Levels"):
        level = int(row["Level"])
        # Same math as Util/LevelCurve.expToNext.
        expected = math.floor(levels["LEVEL_EXP_BASE"] * level ** levels["LEVEL_EXP_EXP"])
        if expected != row["EXP to next"]:
            raise SheetError(
                f"Levels tab, level {level}: the sheet says {row['EXP to next']} EXP but "
                f"floor(LEVEL_EXP_BASE × L^LEVEL_EXP_EXP) gives {expected}. If the level "
                "formula changed, update Util/LevelCurve and check_levels to match."
            )


# ---------------------------------------------------------------------------
# Reading the roster
# ---------------------------------------------------------------------------


def load_roster(path: Path) -> list[dict]:
    # utf-8-sig reads files Excel saved as "CSV UTF-8" (with a BOM) and plain ones.
    with open(path, newline="", encoding="utf-8-sig") as handle:
        rows = [row for row in csv.DictReader(handle) if any((v or "").strip() for v in row.values())]
    roster = []
    seen_ids = set()
    for line, row in enumerate(rows, start=2):
        entry = {key: (value or "").strip() for key, value in row.items()}
        for key in ("island", "islandId", "characterId", "name", "petRarity", "enemyTier"):
            if not entry.get(key):
                raise SheetError(f"{path.name} line {line}: {key} is empty")
        if entry["characterId"] in seen_ids:
            raise SheetError(f"{path.name} line {line}: id {entry['characterId']} is used twice")
        seen_ids.add(entry["characterId"])
        entry["island"] = int(entry["island"])
        roster.append(entry)
    return roster


# ---------------------------------------------------------------------------
# Building the game's definitions from the sheet and roster
# ---------------------------------------------------------------------------


def snake_case(name: str) -> str:
    """'NinjaVillage' -> 'ninja_village'."""
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def stable(number: float) -> float:
    """Round computed numbers to 12 significant digits, so the output is the
    same on every computer (pow can differ in the last bit across systems)."""
    return float(f"{number:.12g}")


def build_islands(tuning: dict, roster: list[dict]) -> list[dict]:
    """One island per island number in the roster. The sheet must have pacing
    numbers for it; a sheet island without roster rows is skipped."""
    island_ids: dict[int, str] = {}
    for entry in roster:
        known = island_ids.setdefault(entry["island"], entry["islandId"])
        if known != entry["islandId"]:
            raise SheetError(f"rosters.csv: island {entry['island']} is both {known} and {entry['islandId']}")

    islands = []
    for number in sorted(island_ids):
        pacing = tuning["islands"].get(number)
        if pacing is None:
            raise SheetError(f"rosters.csv has island {number}, but the Island Pacing tab doesn't")
        previous = tuning["islands"].get(number - 1)
        islands.append(
            {
                "id": island_ids[number],
                "number": number,
                "name": pacing["theme"],
                # Island Pacing lists each island's cost to unlock the next one.
                "unlockCost": previous["nextUnlockCost"] if previous else 0,
                "egg": f"{snake_case(island_ids[number])}_egg",
                "eggCost": pacing["eggCost"],
            }
        )
    return islands


def build_pets(tuning: dict, roster: list[dict]) -> list[dict]:
    pets = []
    for entry in roster:
        factor = tuning["rarityFactor"].get(entry["petRarity"])
        if factor is None:
            raise SheetError(f"{entry['characterId']}: rarity {entry['petRarity']} isn't on the Inputs tab")
        # Same model as Island Pacing's "Bonus per pet" column.
        bonus = tuning["petBaseBonus"] * tuning["petGrowth"] ** (entry["island"] - 1) * factor
        pets.append({**entry, "energyBonus": stable(bonus)})
    return pets


def build_enemies(tuning: dict, roster: list[dict]) -> tuple[list[dict], list[str]]:
    """Enemies for every roster character whose tier has stats on the Enemies
    tab. Returns the enemies and the names skipped for lack of stats."""
    enemies, skipped = [], []
    for entry in roster:
        stats = tuning["enemyStats"].get(entry["island"], {}).get(entry["enemyTier"])
        if stats is None:
            skipped.append(f"{entry['name']} ({entry['enemyTier']})")
            continue
        enemies.append({**entry, **stats})
    return enemies, skipped


def build_eggs(tuning: dict, islands: list[dict], roster: list[dict]) -> list[dict]:
    """Each island's egg holds that island's pet of every rarity on the Egg
    Odds tab, weighted by the tab's base weights."""
    eggs = []
    for island in islands:
        entries = []
        for rarity, weight in tuning["eggOdds"]["weights"].items():
            pets = [e for e in roster if e["island"] == island["number"] and e["petRarity"] == rarity]
            if len(pets) != 1:
                raise SheetError(
                    f"rosters.csv: island {island['number']} needs exactly one {rarity} pet "
                    f"for its egg, found {len(pets)}"
                )
            entries.append({"pet": pets[0]["characterId"], "weight": weight})
        eggs.append({"island": island, "entries": entries})
    return eggs


# ---------------------------------------------------------------------------
# Writing Luau
# ---------------------------------------------------------------------------


def lua_number(value: float) -> str:
    if isinstance(value, bool):
        raise TypeError("expected a number")
    if isinstance(value, int) or (float(value).is_integer() and abs(value) < 2**53):
        return str(int(value))
    return repr(float(value))


def lua_string(text: str) -> str:
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def lua_union(names: list[str]) -> str:
    return " | ".join(lua_string(name) for name in names)


def header(summary: list[str], sources: str) -> list[str]:
    lines = ["--!strict"]
    lines += [f"-- {line}" if line else "--" for line in summary]
    lines += [
        "--",
        f"-- GENERATED by tools/gen_config.py from {sources}.",
        "-- Don't edit by hand: change the sheet or roster, then run",
        "-- `python tools/gen_config.py`.",
        "",
    ]
    return lines


def by_id_footer(kind: str, type_name: str, name: str) -> list[str]:
    return [
        "",
        f"-- {kind} by id.",
        f"local {name}: {{ [string]: {type_name} }} = {{}}",
        "for _, def in list do",
        f"\t{name}[def.id] = table.freeze(def)",
        "end",
        "",
        f"return table.freeze({name})",
        "",
    ]


SHEET = "docs/Anime_Sword_Sim_Tuning.xlsx"
SHEET_AND_ROSTER = "the tuning sheet and docs/rosters.csv (GDD A12a)"


def render_islands(islands: list[dict]) -> str:
    lines = header(
        [
            "Island definitions (GDD A12). Names come from the Island Pacing tab's",
            "Theme column; costs from its Egg cost and unlock cost columns.",
            "unlockCost is the Coins to unlock this island; island 1 is free.",
        ],
        SHEET_AND_ROSTER,
    )
    lines += [
        "export type IslandDef = {",
        "\tid: string,",
        "\t-- Order of play, starting at 1.",
        "\tnumber: number,",
        "\tname: string,",
        "\tunlockCost: number,",
        "\tunlockCurrency: string,",
        "\tegg: string,",
        "}",
        "",
        "local list: { IslandDef } = {",
    ]
    for island in islands:
        lines += [
            "\t{",
            f"\t\tid = {lua_string(island['id'])},",
            f"\t\tnumber = {island['number']},",
            f"\t\tname = {lua_string(island['name'])},",
            f"\t\tunlockCost = {lua_number(island['unlockCost'])},",
            f"\t\tunlockCurrency = {lua_string(COINS)},",
            f"\t\tegg = {lua_string(island['egg'])},",
            "\t},",
        ]
    lines.append("}")
    lines += by_id_footer("Islands", "IslandDef", "Islands")
    return "\n".join(lines)


def render_pets(pets: list[dict], islands: list[dict]) -> str:
    lines = header(
        [
            "Pet definitions (TDD B3 PetDef) from the GDD A12a rosters.",
            "",
            "energyBonus is what one equipped pet adds to the Energy multiplier",
            "(bonuses add together, GDD decision 3): PET_BASE_BONUS × PET_GROWTH ^",
            "(island − 1) × the rarity's pet factor, all from the Inputs tab.",
        ],
        SHEET_AND_ROSTER,
    )
    lines += [
        "local Rarities = require(script.Parent.Rarities)",
        "",
        "export type PetDef = {",
        "\tid: string,",
        "\tname: string,",
        "\trarity: Rarities.Rarity,",
        "\tisland: string,",
        "\tenergyBonus: number,",
        "}",
        "",
        "local list: { PetDef } = {",
    ]
    names = {island["number"]: island["name"] for island in islands}
    current_island = None
    for pet in pets:
        if pet["island"] != current_island:
            if current_island is not None:
                lines.append("")
            current_island = pet["island"]
            lines.append(f"\t-- Island {pet['island']}: {names[pet['island']]}")
        lines += [
            "\t{",
            f"\t\tid = {lua_string(pet['characterId'])},",
            f"\t\tname = {lua_string(pet['name'])},",
            f"\t\trarity = {lua_string(pet['petRarity'])},",
            f"\t\tisland = {lua_string(pet['islandId'])},",
            f"\t\tenergyBonus = {lua_number(pet['energyBonus'])},",
            "\t},",
        ]
    lines.append("}")
    lines += by_id_footer("Pets", "PetDef", "Pets")
    return "\n".join(lines)


def render_enemies(enemies: list[dict], tiers: list[str], skipped: list[str]) -> str:
    summary = [
        "Enemy definitions (GDD A9, A12a). Each roster character is an enemy on",
        "its island and drops its own pet. HP, Coins and EXP per kill come from",
        "the Enemies tab.",
    ]
    if skipped:
        summary += ["", "Left out until the Enemies tab has stats for their tier:"]
        summary += [f"  {name}" for name in skipped]
    lines = header(summary, SHEET_AND_ROSTER)
    lines += [
        f"export type Tier = {lua_union(tiers)}",
        "",
        "export type EnemyDef = {",
        "\tid: string,",
        "\tname: string,",
        "\tisland: string,",
        "\ttier: Tier,",
        "\thp: number,",
        "\tcoins: number,",
        "\texp: number,",
        "\t-- Pet this enemy can drop (DropService rolls the chance).",
        "\tpet: string,",
        "}",
        "",
        "local list: { EnemyDef } = {",
    ]
    for enemy in enemies:
        lines += [
            "\t{",
            f"\t\tid = {lua_string(enemy['characterId'])},",
            f"\t\tname = {lua_string(enemy['name'])},",
            f"\t\tisland = {lua_string(enemy['islandId'])},",
            f"\t\ttier = {lua_string(enemy['enemyTier'])},",
            f"\t\thp = {lua_number(enemy['hp'])},",
            f"\t\tcoins = {lua_number(enemy['coins'])},",
            f"\t\texp = {lua_number(enemy['exp'])},",
            f"\t\tpet = {lua_string(enemy['characterId'])},",
            "\t},",
        ]
    lines.append("}")
    lines += by_id_footer("Enemies", "EnemyDef", "Enemies")
    return "\n".join(lines)


def egg_model_asset(island: dict) -> str:
    """Asset registry key for the egg's model (Config/Assets)."""
    return f"egg.{snake_case(island['id'])}.model"


def render_eggs(eggs: list[dict], pity_threshold: float) -> str:
    lines = header(
        [
            "Egg definitions (TDD B3 EggDef, GDD A6). One egg per island.",
            "",
            "Entry weights are the Egg Odds tab's base weights. Costs come from the",
            "Island Pacing tab's Egg cost column (EGG_COST_BASE × EGG_COST_GROWTH ^",
            "(island − 1)).",
            "",
            "paidRandom must say whether Robux can reach the roll: true if the cost",
            "currency is Robux-buyable, or if a paid luck source can change the odds",
            "(TDD B11). Every egg is true because paid luck applies to all of them,",
            "and a test checks each egg against that rule.",
        ],
        SHEET_AND_ROSTER,
    )
    lines += [
        "local Rarities = require(script.Parent.Rarities)",
        "",
        "export type EggEntry = { pet: string, weight: number }",
        "",
        "export type EggDef = {",
        "\tid: string,",
        "\tisland: string,",
        "\tcost: number,",
        "\tcurrency: string,",
        "\tbonusLuck: number,",
        "\t-- On this many opens without a pet of pityMinRarity or better, the next",
        '\t-- open only rolls those rarities (GDD A6 "Legendary Pity [x/100]").',
        "\tpityThreshold: number,",
        "\tpityMinRarity: Rarities.Rarity,",
        "\tentries: { EggEntry },",
        "\tpaidRandom: boolean,",
        "\tmodelAsset: string,",
        "}",
        "",
        "local list: { EggDef } = {",
    ]
    for egg in eggs:
        island = egg["island"]
        lines += [
            "\t{",
            f"\t\tid = {lua_string(island['egg'])},",
            f"\t\tisland = {lua_string(island['id'])},",
            f"\t\tcost = {lua_number(island['eggCost'])},",
            f"\t\tcurrency = {lua_string(COINS)},",
            "\t\tbonusLuck = 0,",
            f"\t\tpityThreshold = {lua_number(pity_threshold)},",
            f"\t\tpityMinRarity = {lua_string(PITY_MIN_RARITY)},",
            "\t\tentries = {",
        ]
        for entry in egg["entries"]:
            lines.append(f"\t\t\t{{ pet = {lua_string(entry['pet'])}, weight = {lua_number(entry['weight'])} }},")
        lines += [
            "\t\t},",
            "\t\tpaidRandom = true,",
            f"\t\tmodelAsset = {lua_string(egg_model_asset(island))},",
            "\t},",
        ]
    lines.append("}")
    lines += by_id_footer("Eggs", "EggDef", "Eggs")
    return "\n".join(lines)


def render_constants(name: str, summary: list[str], values: dict) -> str:
    lines = header(summary, SHEET)
    lines.append(f"local {name} = {{")
    for key, value in values.items():
        lines.append(f"\t{key} = {lua_number(value)},")
    lines += ["}", "", f"return table.freeze({name})", ""]
    return "\n".join(lines)


def render_levels(levels: dict) -> str:
    return render_constants(
        "Levels",
        [
            'Player level curve (GDD A4), from the Inputs tab\'s "Levels" rows.',
            "",
            "EXP to go from level L to L + 1 = floor(LEVEL_EXP_BASE × L ^ LEVEL_EXP_EXP).",
            "Util/LevelCurve does the math; the generator checks it against the",
            "Levels tab.",
        ],
        levels,
    )


def render_rebirth(rebirth: dict) -> str:
    return render_constants(
        "Rebirth",
        [
            'Rebirth curve (GDD A4), from the Inputs tab\'s "Rebirth" rows.',
            "",
            "Energy cost of the next rebirth with r owned = COST_BASE × COST_GROWTH ^ r.",
            "Multiplier with r owned = (1 + STEP × r) × KICKER ^ floor(r / KICKER_EVERY).",
            "The generator checks these against the Rebirth tab.",
        ],
        rebirth,
    )


def render_combat(combat: dict) -> str:
    return render_constants(
        "Combat",
        [
            "Clicking and combat levers (GDD A4, A10), from the Inputs tab's",
            '"Energy" and "Combat" rows.',
            "",
            "Energy per click = BASE_ENERGY_PER_CLICK × pet multiplier × rebirth",
            "multiplier. START_ENERGY is what a new player starts with. Damage per",
            "hit = Energy × DAMAGE_PER_ENERGY × sword multiplier, times CRIT_MULT on a",
            "crit (CRIT_CHANCE of hits). A sword lands SWING_RATE hits a second.",
        ],
        combat,
    )


def render_traits(traits: dict) -> str:
    order = traits["order"]
    lines = header(
        [
            "Trait reroll odds (GDD A11), from the Traits tab. Each reroll picks a",
            "tier by weight. After HARD_PITY_REROLLS rerolls without the top tier,",
            "the next reroll gives it.",
        ],
        SHEET,
    )
    lines += [
        "local Rarities = require(script.Parent.Rarities)",
        "",
        "local Traits = {",
        "\t-- Lowest tier first; the last one is the top tier pity guarantees.",
        f"\tORDER = {{ {', '.join(lua_string(tier) for tier in order)} }} :: {{ Rarities.Rarity }},",
        "",
        "\tWEIGHTS = {",
    ]
    for tier in order:
        lines.append(f"\t\t{tier} = {lua_number(traits['weights'][tier])},")
    lines += [
        "\t} :: { [Rarities.Rarity]: number },",
        "",
        f"\tHARD_PITY_REROLLS = {lua_number(traits['hardPity'])},",
        "}",
        "",
        "return table.freeze(Traits)",
        "",
    ]
    return "\n".join(lines)


def build_modules(tuning: dict, roster: list[dict]) -> tuple[dict[str, str], list[str]]:
    """File name -> Luau source, plus notes worth printing."""
    islands = build_islands(tuning, roster)
    pets = build_pets(tuning, roster)
    enemies, skipped = build_enemies(tuning, roster)
    eggs = build_eggs(tuning, islands, roster)

    notes = []
    if skipped:
        notes.append("No Enemies-tab stats for: " + ", ".join(skipped))
    unused = sorted(set(tuning["islands"]) - {island["number"] for island in islands})
    if unused:
        notes.append(f"Skipped sheet islands with no roster rows yet: {', '.join(map(str, unused))}")

    modules = {
        "Islands.luau": render_islands(islands),
        "Pets.luau": render_pets(pets, islands),
        "Enemies.luau": render_enemies(enemies, tuning["tiers"], skipped),
        "Eggs.luau": render_eggs(eggs, tuning["eggOdds"]["pityThreshold"]),
        "Levels.luau": render_levels(tuning["levels"]),
        "Rebirth.luau": render_rebirth(tuning["rebirth"]),
        "Traits.luau": render_traits(tuning["traits"]),
        "Combat.luau": render_combat(tuning["combat"]),
    }
    return modules, notes


# ---------------------------------------------------------------------------
# Command line
# ---------------------------------------------------------------------------


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--sheet", type=Path, default=DEFAULT_SHEET, help="tuning .xlsx")
    parser.add_argument("--csv", type=Path, help="folder of CSV exports, one per tab")
    parser.add_argument("--roster", type=Path, default=DEFAULT_ROSTER, help="roster CSV")
    parser.add_argument("--out", type=Path, default=CONFIG_DIR, help="config folder to write")
    parser.add_argument("--check", action="store_true", help="only check the files are up to date")
    args = parser.parse_args()

    try:
        grids = read_csv_folder(args.csv) if args.csv else read_xlsx(args.sheet)
        modules, notes = build_modules(load_tuning(grids), load_roster(args.roster))
    except SheetError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    for note in notes:
        print(f"note: {note}")

    if not args.check:
        args.out.mkdir(parents=True, exist_ok=True)

    stale = []
    for name, source in modules.items():
        path = args.out / name
        current = path.read_text(encoding="utf-8") if path.exists() else None
        if current == source:
            continue
        stale.append(name)
        if not args.check:
            path.write_text(source, encoding="utf-8", newline="\n")

    if args.check:
        if stale:
            print("Out of date with the sheet: " + ", ".join(stale), file=sys.stderr)
            print("Run `python tools/gen_config.py` and commit the result.", file=sys.stderr)
            return 1
        print("Config modules match the sheet.")
    else:
        print("Updated: " + ", ".join(stale) if stale else "Already up to date.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
