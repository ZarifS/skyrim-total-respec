# Total Respec — Nexus Mod Page Copy

> Author: **OriginalZee** · Version: **1.0.0** · Skyrim SE/AE (1.5.97 / 1.6.x) · License: **MIT**
> Copy each section into the matching field on the Nexus mod page.

---

## Summary (one-liner)

A single potion that fully respecs your character — refunds every perk and re-runs Skyrim's own level-up screen so you re-pick your Health/Magicka/Stamina the vanilla way. Sold only by the Khajiit caravans.

---

## Description

**Total Respec** is a clean, one-potion character reset. Drink the **Draught of Renewal**, confirm, and the mod:

1. **Refunds every perk you've ever spent** — across all 18 skill trees, including perks added by overhauls like Ordinator, Vokrii, or Adamant (it uses SKSE perk-tree introspection, not a hardcoded vanilla list).
2. **Resets your base Health, Magicka, Stamina, and Carry Weight** to configurable baselines.
3. **Re-runs Skyrim's native level-up flow** — your level drops to 1 and your XP is restored, so the engine queues up all your level-ups again and you re-allocate one attribute point per level through the standard **Skills → "Level Up!"** screen. No custom menus, no scripted attribute math — it's the engine's own robust system.

Your skill levels are untouched (Smithing 80 stays Smithing 80) — only perks and attribute allocations are reset.

The attribute baselines are read from a JSON file, so it plays nicely with attribute-rebasing mods (e.g. SkyValor): set the baselines to match and your modded base values are preserved.

---

## Main features

- **Full perk refund** across every skill tree, mod-added perks included.
- **Bonus perks preserved** — if you have extra perk points from Oghma Infinium or similar, the math keeps them; only legitimately-spent points are refunded.
- **Vanilla attribute re-allocation** — re-pick H/M/S through Skyrim's own level-up screen, the engine-native way to permanently set base attributes.
- **Configurable baselines** — edit `Data/SKSE/Plugins/TotalRespec.json` (`baselineHealth/Magicka/Stamina/CarryWeight`) to match your setup; defaults are vanilla 100/100/100/300.
- **Carry-weight correct** — properly accounts for the +5 carry weight per Stamina pick across the reset, no drift.
- **Confirmation prompt** — drinking asks before doing anything; "Back" returns the potion.
- **Lightweight** — one potion, one magic effect, one script. No MCM.

---

## Requirements

- **Skyrim SE/AE** (runtime 1.5.97 or 1.6.x)
- **SKSE64**
- **JContainers SE** — used to read the JSON baseline config
- **SkyPatcher** — used to place the potion on the Khajiit caravans

---

## Installation instructions

1. Install the requirements above (SKSE64, JContainers SE, SkyPatcher).
2. Install **Total Respec** with your mod manager and enable `TotalRespec.esp`.
3. *(Optional)* edit `Data/SKSE/Plugins/TotalRespec.json` to set your attribute baselines (e.g. if you use SkyValor or a custom-race mod).
4. **Buy the Draught of Renewal from a Khajiit caravan** — Ri'saad's caravans that travel between the holds. (It is intentionally sold *only* by the caravans.) Merchant stock refreshes every couple of days, so check back if it isn't listed.
5. Drink it when you want to respec, confirm, then open the Skills menu and click **"Level Up!"** for each queued level to re-allocate your attributes.

> **Survival Mode:** the level-up menu is gated behind sleeping — sleep in a bed after drinking to access your queued level-ups.

---

## Shout outs

- **Ishmaeltheforsaken** — [Ish's Respec Mod](https://www.nexusmods.com/skyrimspecialedition/mods/1960), whose `ActorValueInfo.GetPerkTree` perk-refund approach this reuses.
- **SKSE** team — the script extender that makes perk-tree introspection possible.
- **silverlock / JContainers SE** authors — the JSON config layer.
- **SkyPatcher** author — the runtime patcher used for caravan distribution.
- **Mutagen.Bethesda** — the plugin-authoring library the ESP is built with.

> Licensed **MIT**. Source: <https://github.com/ZarifS/total-respec>
