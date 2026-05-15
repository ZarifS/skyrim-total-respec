# Total Respec

A single-potion mid-game respec for Skyrim SE (AE / 1.6.x) that refunds **all perks** and grants a lesser power for **redistributing your H/M/S/Carry-Weight allocations**. Built to coexist cleanly with [SkyValor](https://www.nexusmods.com/skyrimspecialedition/mods/91465) (or any mod that re-bases player attributes): **the mod never resets H/M/S/CW to a hardcoded value** — every attribute change goes through `ModActorValue(±10)` so any mod-applied baseline (like SkyValor's 300 base health) is preserved untouched.

Inspired by [Ish's Respec Mod](https://www.nexusmods.com/skyrimspecialedition/mods/1960) — uses the same SKSE `ActorValueInfo.GetPerkTree` introspection so mod-added perks (Ordinator, Vokrii, SkyValor, etc.) are all refunded, not just vanilla.

## What it does

When you drink **Draught of Renewal**:

1. **Refunds every perk you've ever spent**, across every skill tree, including perks added by other mods. The refunded count is returned via `Game.ModPerkPoints` so you can re-spend in the skill menu.
2. **Grants the "Adjust Attributes" lesser power** (added once; persistent).
3. **Shows a summary**: "X perks refunded. You may redistribute up to Y attribute points." (Y = `playerLevel − 1`, the standard vanilla allocation count.)

Then, whenever you want, cast **Adjust Attributes** to open a redistribution menu:

```
Current: Health 520, Magicka 100, Stamina 100. Net change: 0.

[Health -10]  [Magicka -10]  [Stamina -10 (-5 CW)]
[Health +10]  [Magicka +10]  [Stamina +10 (+5 CW)]
[Done]
```

Each button is a single `ModActorValue` step. You can apply as many in a row as you want. The menu shows your current base values live. **Net change must reach 0 before you can exit** — the mod enforces this so you can only *redistribute*, never net-gain stats.

## Why delta-only (preserves SkyValor's 300 base health)

The first version of this mod reset Health/Magicka/Stamina to 100 and CarryWeight to 300. That works for unmodded Skyrim but **clobbers any mod that re-bases player attributes** — SkyValor, for example, sets base health to 300 via SkyPatcher; resetting to 100 would visibly drop the player's health pool.

The delta approach (this version) never reads or writes a base "target" value. It only calls `ModActorValue(av, +10)` or `ModActorValue(av, -10)`. Whatever the underlying base is — vanilla 100, SkyValor 300, Aetherius custom — stays untouched. The redistribution only operates on the player's *deltas relative to whatever base the mods established*.

## What it does NOT do

- **Does not change your skill levels.** Smithing 80 stays Smithing 80. Only perks spent on the tree get refunded.
- **Does not enforce per-attribute investment tracking.** The mod doesn't know how you originally split your points between H/M/S, so it can't auto-undo your specific allocation. Instead, it gives you an unbounded "+10/−10 per click" tool and asks you to balance net change to 0 manually.
- **Does not touch perks outside skill trees.** Hidden multiplier perks added by mods (e.g., SkyValor's global damage perks) live outside any skill tree's perk chain; `GetPerkTree` ignores them, and they survive the respec correctly.
- **Does not refund attribute points granted outside vanilla rules** (e.g., Aetherius bonus points). Only the vanilla `level − 1` attribute point count is shown as the redistribution budget; if your build uses bonus points from another mod, redistribute manually.

## Requirements

- Skyrim SE / AE, runtime 1.5.97 or 1.6.x
- SKSE64 (any modern version — `ActorValueInfo` and `Game.ModPerkPoints` are old SKSE features)
- Tested against runtime **1.6.1170** with SKSE 2.2.6

## Installation

1. Build (see below) or download a release zip.
2. Install through your mod manager.
3. Enable `TotalRespec.esp` in load order.
4. The potion is not distributed to vendors — add it via console:
   - `help "Draught of Renewal" 0` to find the FormID, then
   - `player.additem <formid> 1`

## Building

### Prerequisites

| Tool | Why |
|---|---|
| [.NET 9 SDK](https://dotnet.microsoft.com/download) | Builds the Mutagen-based ESP project |
| [Caprica](https://www.nexusmods.com/skyrimspecialedition/mods/56120) | Compiles Papyrus `.psc` → `.pex` |

### Build

```bash
bash build.sh                    # build only
bash build.sh --deploy           # build and copy into MO2 mods/Total Respec/
```

Output lives at `dist/Total Respec/`.

## Repo layout

```
total-respec/
├── README.md
├── build.sh
├── esp/
│   └── EspBuilder/             — Mutagen / C# project that emits the ESP
│       └── EspBuilder/
│           ├── EspBuilder.csproj
│           └── Program.cs
├── scripts/
│   ├── TR_RenewalEffect.psc           — Potion script: perk refund + grant Adjust power
│   └── TR_AdjustAttributesEffect.psc  — Adjust-power script: looping ±10 menu
└── dist/                        — generated; safe to delete
```

## Record map

| Type | EditorID | Purpose |
|---|---|---|
| ALCH | `TR_RenewalPotion` | Master potion — drink to refund perks and gain Adjust Attributes power |
| MGEF | `TR_RenewalEffect` | Runs the perk-refund script |
| MGEF | `TR_AdjustAttributesEffect` | Runs the ±10 redistribution menu |
| SPEL | `TR_AdjustAttributesPower` | Lesser power, granted by the potion, opens the menu |
| MESG | `TR_AdjustMsg` | 7-button menu (H− / M− / S− / H+ / M+ / S+ / Done) |
| MESG | `TR_SummaryMsg` | One-shot post-drink announcement |
| GLOB | `TR_LastPerkRefund` | Count of perks just refunded (for summary message) |
| GLOB | `TR_LastAttrCount` | `level − 1` (for summary message) |
| GLOB | `TR_NetDelta` | Running net change in stamina-equivalent units; must reach 0 to exit |
| GLOB | `TR_CurrentHealth`, `TR_CurrentMagicka`, `TR_CurrentStamina` | Live values shown in adjust menu |
| FLST | `TR_PerkWorkingList` | Scratch list for `ActorValueInfo.GetPerkTree` |

## How the perk refund works (technical)

The script iterates each of the 18 vanilla skill names and calls SKSE's `ActorValueInfo.GetPerkTree(list, player, unowned=False, allRanks=True)`. That function walks the perk chain attached to the skill's AV and populates the FormList with every perk *the player currently has* in that tree — including perks added by mods to that tree. We then `RemovePerk` each one and `Game.ModPerkPoints` for the total.

This is identical to the modern (SKSE 1.7.3+) branch of [Ish's Respec Mod](https://www.nexusmods.com/skyrimspecialedition/mods/1960). Credit to Ishmaeltheforsaken for the original approach.

## How the attribute redistribution works

Vanilla Skyrim grants one attribute point per character level past 1, applied as `+10` to the chosen `Health` / `Magicka` / `Stamina` base actor value (Stamina also bumps `CarryWeight` by `+5`). The Adjust Attributes power lets you reverse and re-apply those increments:

- Each menu button calls `Actor.ModActorValue("Health", ±10)` (etc.). This is a pure delta operation on the base AV.
- Mod-applied bases (e.g., SkyValor's 300 base health) sit underneath these deltas and stay untouched.
- A `TR_NetDelta` global tracks total ±10 changes within this menu session. **Done** is only accepted when net delta = 0 so you can redistribute but not net-gain stats.

If you cast Adjust Attributes a second time later, `TR_NetDelta` resets to 0 for that new session — you can do another round of redistribution.

## Compatibility

- **SkyValor**: tested. SkyValor's player script adds 4 hidden multiplier perks that aren't in any skill tree, so `GetPerkTree` doesn't see them; they survive the respec. SkyValor's base-health patch (300) survives because the mod is delta-only.
- **Ordinator / Vokrii / Adamant / etc.**: any perk-overhaul that attaches perks to vanilla skill trees works automatically.
- **Aetherius / Imperious / Custom Races**: mod-applied attribute bases survive (delta-only). Bonus attribute points beyond vanilla `level − 1` are not auto-counted; manage manually.
- **Mods that apply temporary modifiers to H/M/S/CW via spells or abilities** (Standing Stones, enchanted gear): unaffected — those live on top of the base AV, not in it.

## License

MIT.

## Credits

- [Ishmaeltheforsaken](https://www.nexusmods.com/skyrimspecialedition/users/1960) — original Ish's Respec Mod, whose `ActorValueInfo.GetPerkTree` pattern this mod reuses
- [Mutagen.Bethesda](https://github.com/Mutagen-Modding/Mutagen) — clean Bethesda plugin authoring API
- [Caprica](https://www.nexusmods.com/skyrimspecialedition/mods/56120) — Papyrus compiler used in the build pipeline
