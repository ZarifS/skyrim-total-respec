# Total Respec

A single-potion character respec for Skyrim SE/AE (1.5.97 or 1.6.x). Drink the **Draught of Renewal** to refund every perk and re-allocate your attributes through Skyrim's *own* level-up screen — no custom menus, no scripted attribute math.

By **OriginalZee**. MIT licensed.

## What it does

Drinking the Draught of Renewal (after a confirmation prompt):

1. **Refunds every perk you've spent** across all 18 skill trees, via SKSE's `ActorValueInfo.GetPerkTree` introspection — so mod-added perks (Ordinator, Vokrii, Adamant, …) are refunded too, not just vanilla. Bonus perk points (e.g. Oghma Infinium) are preserved; only legitimately-spent points are returned.
2. **Resets base Health / Magicka / Stamina / Carry Weight** to configurable baselines.
3. **Re-runs the native level-up flow** — drops you to level 1, restores your XP, and lets the engine queue all your level-ups so you re-pick attributes via the standard **Skills → "Level Up!"** screen.

Skill *levels* are never touched (Smithing 80 stays 80). Only perks and attribute allocations reset.

> In **Survival Mode**, the level-up menu is gated behind sleeping — sleep after drinking to access the queued level-ups.

## Configurable baselines

Reset targets are read at runtime from `Data/SKSE/Plugins/TotalRespec.json`:

```json
{
  "baselineHealth": 100,
  "baselineMagicka": 100,
  "baselineStamina": 100,
  "baselineCarryWeight": 300
}
```

Defaults are vanilla race-base values. Using an attribute-rebasing mod (SkyValor, custom race)? Set these to match and your modded bases survive the respec. The Carry-Weight +5-per-Stamina-pick bonus is reconciled across the reset so nothing drifts.

## Where you get it

The Draught of Renewal is sold **only by the Khajiit caravans** (Ri'saad's traders). Vanilla has no caravan-exclusive leveled list — the caravans share general-vendor lists with every merchant — so distribution is done by injecting the potion directly into the three caravan merchant chests (`MerchantCaravanAChest/B/C`, `Skyrim.esm` `0x07434B / 0x07434D / 0x07434E`) via **SkyPatcher**. That keeps it caravan-only. The generated config lives at `SKSE/Plugins/SkyPatcher/container/TotalRespec/TotalRespec.ini`.

## Requirements

- Skyrim SE/AE, runtime 1.5.97 or 1.6.x
- SKSE64
- **JContainers SE** — reads the JSON baseline config (`JValue`/`JMap`)
- **SkyPatcher** — places the potion on the Khajiit caravans

No SkyUI/MCM needed.

## Building

| Tool | Why |
|---|---|
| [.NET 9 SDK](https://dotnet.microsoft.com/download) | builds the Mutagen ESP project |
| [Caprica](https://www.nexusmods.com/skyrimspecialedition/mods/56120) | compiles Papyrus `.psc` → `.pex` |
| JContainers SE installed in MO2 | provides the Papyrus headers the script imports |

```bash
bash build.sh            # build to dist/Total Respec/
bash build.sh --deploy   # also copy into MO2 mods/Total Respec/
```

`build.sh` runs the Mutagen `EspBuilder`, which emits both `TotalRespec.esp` and the SkyPatcher container INI.

## Repo layout

```
total-respec/
├── README.md
├── build.sh
├── config/TotalRespec.json          baseline config shipped to SKSE/Plugins/
├── esp/EspBuilder/                  Mutagen C# project that emits the ESP + SkyPatcher INI
│   └── EspBuilder/Program.cs
├── scripts/TR_RenewalEffect.psc     potion magic-effect script (perk refund + reset + re-level)
└── dist/                            generated; safe to delete
```

## Record map

| Type | EditorID | Purpose |
|---|---|---|
| ALCH | `TR_RenewalPotion` | The Draught of Renewal — drink to respec (FormID `0x000803`) |
| MGEF | `TR_RenewalEffect` | Script effect: refund perks, reset to baselines, re-level |
| MESG | `TR_ConfirmMsg` | Confirm modal shown on drink |
| FLST | `TR_PerkWorkingList` | Scratch list for `GetPerkTree` |

## Credits

- [Ishmaeltheforsaken](https://www.nexusmods.com/skyrimspecialedition/mods/1960) — Ish's Respec Mod, whose `GetPerkTree` perk-refund pattern this reuses
- [Mutagen.Bethesda](https://github.com/Mutagen-Modding/Mutagen) — plugin authoring library
- [JContainers SE](https://www.nexusmods.com/skyrimspecialedition/mods/16495) — JSON config layer
- [SkyPatcher](https://www.nexusmods.com/skyrimspecialedition/mods/106659) — runtime container patcher for caravan distribution
- [Caprica](https://www.nexusmods.com/skyrimspecialedition/mods/56120) — Papyrus compiler used in the build
