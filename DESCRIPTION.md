# Total Respec

*A clean, one-potion character respec for Skyrim SE/AE — by **OriginalZee***

---

## What this mod is

**Total Respec** gives you a single potion — the **Draught of Renewal** — that fully respecs your character using Skyrim's *own* systems, not a bolted-on custom menu.

Drink it, confirm, and the mod:

1. **Refunds every perk you've ever spent**, across all 18 skill trees.
2. **Resets your base Health, Magicka, Stamina, and Carry Weight** to configurable baselines.
3. **Re-runs Skyrim's native level-up flow** so you re-pick your attributes through the vanilla **Skills → "Level Up!"** screen.

Your skill *levels* are never touched — Smithing 80 stays Smithing 80. Only perks and attribute allocations are reset, exactly the things a respec should change.

---

## How it works

**Perk refund.** Rather than a hardcoded list of vanilla perks, Total Respec uses SKSE's `ActorValueInfo.GetPerkTree` to walk every skill tree and find the perks you actually have — so perks added by overhauls (Ordinator, Vokrii, Adamant, etc.) are refunded too, not just vanilla ones. It also *preserves bonus perk points*: if you gained extra points from something like the Oghma Infinium, the refund math keeps them and only returns legitimately-spent points.

**Attribute reset, the engine-native way.** Instead of scripting attribute math (which is fragile and fights attribute-rebasing mods), Total Respec drops your level to 1, sets your base H/M/S/CW to the configured baselines, then restores your original XP. Skyrim responds by queueing up all your level-ups again — and you re-allocate one attribute point per level through the standard level-up screen, the same robust path the game uses normally. It also carefully accounts for the +5 Carry Weight that each Stamina pick grants, so nothing drifts across the reset.

**Configurable baselines.** The reset targets are read from `Data/SKSE/Plugins/TotalRespec.json`:

```json
{
  "baselineHealth": 100,
  "baselineMagicka": 100,
  "baselineStamina": 100,
  "baselineCarryWeight": 300
}
```

Defaults are vanilla race-base values. If you run an attribute-rebasing mod (e.g. SkyValor) or a custom race, set these to match and your modded base values are preserved through the respec.

---

## Where you get it

The Draught of Renewal is sold **only by the Khajiit caravans** — Ri'saad's traders that travel between the holds (Ahkari, Ma'randru-jo, and Ri'saad's groups). It is intentionally exclusive to them; no other merchant stocks it. Caravan inventory refreshes every couple of in-game days, so check back if it isn't currently listed.

*(Technical note: there is no caravan-exclusive leveled list in vanilla — the caravans share general-vendor lists with every other merchant — so distribution is done by injecting the potion directly into the three caravan merchant chests via SkyPatcher. That's what keeps it caravan-only.)*

---

## Requirements

- **Skyrim SE/AE** (runtime 1.5.97 or 1.6.x)
- **SKSE64**
- **JContainers SE** — reads the JSON baseline config
- **SkyPatcher** — places the potion on the Khajiit caravans

No SkyUI/MCM required.

---

## Installation

1. Install the requirements above.
2. Install Total Respec with your mod manager and enable `TotalRespec.esp`.
3. *(Optional)* edit `Data/SKSE/Plugins/TotalRespec.json` to match your attribute setup.
4. Buy the **Draught of Renewal** from a Khajiit caravan.
5. Drink it, confirm, then open the Skills menu and click **"Level Up!"** for each queued level to re-allocate H/M/S.

> **Survival Mode:** the level-up menu only opens after sleeping — sleep in a bed after drinking to access your queued level-ups.

---

## Compatibility

- **Perk overhauls** (Ordinator / Vokrii / Adamant / etc.) — supported automatically; any perk attached to a vanilla skill tree is refunded.
- **Attribute-rebasing mods** (SkyValor, custom races) — set the JSON baselines to match and your modded bases are preserved.
- **Skill levels, gear, enchantments, standing stones** — untouched; the respec only resets perks and base H/M/S/CW.

---

## Credits

- **Ishmaeltheforsaken** — [Ish's Respec Mod](https://www.nexusmods.com/skyrimspecialedition/mods/1960), whose `ActorValueInfo.GetPerkTree` perk-refund pattern this reuses.
- **SKSE** team — the script extender behind the perk-tree introspection.
- **JContainers SE** — the JSON config layer.
- **SkyPatcher** author — the runtime patcher used for caravan distribution.
- **Mutagen.Bethesda** — the library the plugin is authored with.

---

## License

Released under the **MIT License**. Source: <https://github.com/ZarifS/total-respec>
