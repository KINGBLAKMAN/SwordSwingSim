# MVP playtest (plan D2 exit test)

The D2 exit criteria: a new player plays 15 minutes, opens about 20 eggs,
feels the pet power jump, unlocks island 2, rejoins with everything intact,
and the funnel events show where players drop off.

Each check below names what to look at and what "pass" means. Note the
time and your Coins at each **⏱** mark, because those numbers are what
tells us whether the tuning sheet's pacing is right.

## Before you start

1. `git checkout main`, then `git pull`, then reopen the place so Rojo syncs.
2. Turn on **File → Experience Settings → Security → Enable Studio Access to API
   Services**. Without it ProfileStore can't save, and the rejoin test means
   nothing.
3. Publish the place once if you haven't. The 2x Coins pass and the Energy
   Pack only work in a published place.
4. Use a fresh profile. Temporarily change `STORE_NAME` in `Config/Data`
   (for example to `"PlayerData_test1"`), or test on an alt account, so you
   start as a new player. Change it back before you commit.
5. View → Output stays open the whole time. Any red error fails the run.

## Solo run (15 minutes, start a stopwatch)

| # | Do | Pass when |
|---|----|-----------|
| 1 | Press Play. | You spawn on Ninja village with 500 Energy. The quest tracker reads "Defeat 25 Kōhai 0 / 25". |
| 2 | Tap **Click!** a few times, then turn on **Auto**. | Energy goes up on each click, and Auto keeps adding about 3 per second. |
| 3 | Walk to the Kōhai ring and let auto-attack work. | HP bars drop, damage numbers pop (yellow for crits), and each kill gives Coins plus a drop toast. |
| 4 | Tap an enemy. | The info panel lists its drops with chances. Karasu Ren's list includes Crowfeather Tachi at 1%. |
| 5 | Open the first egg at 25 Coins. | The egg shakes, cracks and reveals a pet with "New!". **⏱ time to first egg.** |
| 6 | Tap **Details** on the egg board. | The odds add up to 100% and show Legendary pity x/100. |
| 7 | Open **Pets** and tap **Equip Best**. | A ball follows you and Energy per click rises. This is the "pet power jump". Compare clicks before and after. |
| 8 | Keep looping: kill, open, Equip Best. Claim each quest. | All 3 Ninja village quests are claimed, the last one by beating Karasu Ren. **⏱ time when the chain is done.** |
| 9 | Keep going until you've opened about 20 eggs. | **⏱ time at 20 eggs.** Pass: under about 15 minutes. |
| 10 | Get 1,200 Coins, use the blue gate and tap **Unlock**. | You land on Cursed-spirit city and its first quest starts. **⏱ time to island 2.** |
| 11 | On island 2, kill a few Haiiro Wisp and open one 625-Coin egg if you can. | Talisman Token and Curse Shard drops appear, and so do island 2 pets. |
| 12 | Open **Store** and buy 2x Coins (Studio test purchases are free). | It shows "Owned" and kills now give twice the Coins. |
| 13 | Buy the Energy Pack. | +2,500 Energy, exactly once. |
| 14 | Stop, then Play again. | Same island, Coins, Energy, pets, equipped pets, locks, quest progress and 2x Coins. Nothing reset. |

If 20 eggs or island 2 takes far longer than 15 minutes, don't change any
code. Note the ⏱ times and Coins and we'll tune `docs/Anime_Sword_Sim_Tuning.xlsx`.

## Two-player run

In Studio, open **Test → Clients and Servers**, set it to **2 Players** and
press **Start**. You get one server window and two player windows.

| # | Do | Pass when |
|---|----|-----------|
| 1 | Both players equip pets. | Each player sees the other's pets following them. |
| 2 | Player 2 turns on Settings → "Hide other players' pets". | Player 1's pets disappear for player 2 only. |
| 3 | Both players hit the same Elder Kurogane. | Both get the kill reward and drops (shared credit for ≥10% damage), and both quest counters move if the quest matches. |
| 4 | Player 1 opens an egg. | Only player 1 sees the hatch. Player 2 sees nothing. |
| 5 | Player 1 unlocks island 2 (finish the quests first) and travels. | Player 2 stays on island 1. Island 1's enemies keep spawning for player 2, and island 2's run for player 1. |
| 6 | Player 2 tries the gate. | The screen says "Finish the Ninja village quests to unlock". Player 2 can't get to island 2. |
| 7 | Close player 1's window. | Player 1's pets vanish for player 2, and the Output shows no errors. |

## Funnel check (after publishing)

Play once in the published game as a new player. In **Creator Dashboard →
Analytics → Funnels → Onboarding**, these steps should show up in order:

1. Joined
2. FirstClick
3. FirstKill
4. FirstEgg
5. FirstEquip
6. FirstQuestClaimed
7. Island2Unlocked

The dashboard can take a day to update. Studio doesn't send analytics.
