# Ardikhj/roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Ardikhj/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Ardikhj/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bay — Steal a Snackrot**: a 3D Roblox brainrot game. Eighteen absurd original characters walk the belt and earn money per second. Buy them, park them on your base, lock the base against thieves, slap the thieves anyway, outrun the tsunami wave, and rebirth for a permanent earnings multiplier. Built by an AI agent for make.fun's “Make the best AI Roblox brainrot game” bounty, $1,000 in USDC.

## The game

- **The cast** — 18 original brainrots on six rarities (Common → Secret): Sir Crocs-a-Lot, DJ Flush, Pigeon CEO, Banana Phone Boi, Grandma's WiFi, Soggy Cereal Knight, Turbo Toaster Cat, Llama in a Lambo, Pickle Wizard, Sir Reginald III, The Unpaid Intern, Couch Potato King, Quantum Quokka, The Algorithm, Grandma's Revenge, The Ohio Boss, Admin's Lost Sandwich, Golden Capybara Founder. Five mutations (Golden, Diamond, Rainbow, Lava) multiply earnings up to 15×.
- **The loop** — brainrots spawn at the north tunnel, walk the belt, and despawn at the exit. Buy one with a ProximityPrompt and it walks to your base slot and earns every second. The next tier is always one good catch away.
- **The threats** — any player can steal off an unlocked base (the brainrot follows the thief home, 25 s to escape); the owner slaps (F) to make them drop it. Every 150 s a tsunami wall sweeps the map: anyone caught outside their own base is flung back to spawn and slowed, and the belt washes clean.
- **Progression** — base lock (60 s, 90 s recharge), rebirth (5× cost growth, +50% earnings per rebirth, new aura), DataStore saves of cash and rebirths, leaderstats (Cash, $/s, Rebirths).

## Run it

```sh
rojo build default.project.json --output game.rbxl   # Rojo 7.7+
# Open game.rbxl in Roblox Studio and press Play.
# Or run the hand-in program exactly as the grader does:
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` (Node 22, standard library only) copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to the output directory and writes `dossier.json` with the kit's vendored `vendor/makefun-roblox.ts`, unchanged.

## Layout

- `src/shared/` — `BrainrotCatalog.luau` (cast, rarities, mutations), `Config.luau` (all tuning), `Format.luau` (money/clock text)
- `src/server/` — `init.server.luau` (bootstrap), `DataService` (player state, leaderstats, saves), `BrainrotService` (belt spawns, buying, 3D models), `BaseService` (bases, locks, stealing, slapping), `EconomyService` (1 s earnings tick), `WaveService` (tsunami), `RebirthService` (prestige), `WorldBuilder` (title sign, base banners)
- `src/client/` — `Game.client.luau` (wiring), `Hud.luau` (ScreenGui: cash, income, lock, rebirth, wave banner, toasts, rarity legend), `Effects.luau` (camera shake, flashes)
- `tools/generate_project.py` — regenerates `default.project.json` (the 3D world: baseplate, belt, tunnels, 8 bases, trees, lamps, wave wall)
- `tools/make_screenshots.py` — draws the `screenshots/` mockups (see below)

## Status — what is BLOCKED and why (read before judging)

This entry was built on Linux, where Roblox Studio does not exist (the bounty prerequisites require Studio on Windows/macOS). What that blocks, honestly:

1. **No published place.** `PLAY.json` still names place `0`: there is no Roblox account available to this build, and only the account owner can publish a Public experience, pass the age check, set the description/play code, and upload the icon and thumbnail. Nothing here is published.
2. **No Studio screenshots.** `screenshots/` holds **concept mockups drawn with PIL**, each watermarked `CONCEPT MOCKUP — NOT A STUDIO CAPTURE`. They are diagrams of the intended game, not captures of it running in Studio, and none of them is a Roblox thumbnail. They must be replaced with real Studio captures before any submission.
3. **Never run in Studio.** All 14 Luau files parse with the Luau compiler and the Rojo-built `game.rbxl` contains exactly those 14 scripts (100% source match, verified with the kit's own `buildDossier` library), but the game has not been play-tested in Studio. First run in Studio is the remaining step.

What *is* done: the full 3D world as a Rojo project, the complete server/client game code, the hand-in program, and a verified deterministic `dossier.json`. With a Windows/Mac machine, a Roblox account that can already publish, and about an hour in Studio (open `game.rbxl`, Play, take 3 captures, publish Public, set description + icon + thumbnail, fill in `PLAY.json`), this becomes a submittable entry.

---

<sub>Entered on [make.fun](https://make.fun/?ref=dz40rs9a&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
