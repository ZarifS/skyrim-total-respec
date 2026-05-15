using Mutagen.Bethesda.Plugins;
using Mutagen.Bethesda.Plugins.Records;
using Mutagen.Bethesda.Skyrim;

var modKey = ModKey.FromNameAndExtension("TotalRespec.esp");
var mod = new SkyrimMod(modKey, SkyrimRelease.SkyrimSE);

mod.ModHeader.Author = "meteor";
mod.ModHeader.Description = "Total Respec - one potion: confirm, refund all perks, reset H/M/S/CW to baselines from Data/SKSE/Plugins/TotalRespec.json, then spend (level-1) tokens on H/M/S.";

// ---------- FormList ----------
var perkWorkingList = new FormList(mod.GetNextFormKey(), SkyrimRelease.SkyrimSE)
{
    EditorID = "TR_PerkWorkingList",
};
mod.FormLists.Add(perkWorkingList);

// ---------- Confirm Message ----------
var confirmMsg = new Message(mod.GetNextFormKey(), SkyrimRelease.SkyrimSE)
{
    EditorID = "TR_ConfirmMsg",
    Name = "Draught of Renewal",
    Description =
        "This will reset your character: every perk point will be refunded and your Health, " +
        "Magicka, Stamina, and Carry Weight will be reset to their baseline values (configured in " +
        "Data/SKSE/Plugins/TotalRespec.json). You will then re-allocate one attribute point per " +
        "character level past 1. Proceed?",
    DisplayTime = 0,
    Flags = Message.Flag.MessageBox,
};
confirmMsg.MenuButtons.Add(new MessageButton { Text = "Continue (begin reset)" });
confirmMsg.MenuButtons.Add(new MessageButton { Text = "Back (cancel - return potion)" });
mod.Messages.Add(confirmMsg);

// Helper: build a ScriptObjectProperty by FormKey
static ScriptObjectProperty Prop(string name, FormKey key) =>
    new ScriptObjectProperty
    {
        Name = name,
        Flags = ScriptProperty.Flag.Edited,
        Object = new FormLink<ISkyrimMajorRecordGetter>(key),
    };

// ---------- Renewal Effect (script attached) ----------
var renewalEffect = new MagicEffect(mod.GetNextFormKey(), SkyrimRelease.SkyrimSE)
{
    EditorID = "TR_RenewalEffect",
    Name = "Renewal",
    Description = "Refunds perks, resets attributes to baseline, and runs the token-spend menu.",
    BaseCost = 0f,
    TaperWeight = 0f,
    TaperCurve = 0f,
    TaperDuration = 0f,
    MinimumSkillLevel = 0,
    CastingSoundLevel = SoundLevel.Silent,
    Flags = MagicEffect.Flag.NoHitEvent | MagicEffect.Flag.NoDeathDispel,
    Archetype = new MagicEffectArchetype
    {
        Type = MagicEffectArchetype.TypeEnum.Script,
        ActorValue = ActorValue.None,
    },
    CastType = CastType.FireAndForget,
    TargetType = TargetType.Self,
    SecondActorValue = ActorValue.None,
    VirtualMachineAdapter = new VirtualMachineAdapter
    {
        Version = 5,
        ObjectFormat = 2,
    },
};
var renewalScript = new ScriptEntry
{
    Name = "TR_RenewalEffect",
    Flags = ScriptEntry.Flag.Local,
};
renewalScript.Properties.Add(Prop("TR_ConfirmMsg",      confirmMsg.FormKey));
renewalScript.Properties.Add(Prop("TR_PerkWorkingList", perkWorkingList.FormKey));
// TR_RenewalPotion bound below once the potion exists.
renewalEffect.VirtualMachineAdapter!.Scripts.Add(renewalScript);
mod.MagicEffects.Add(renewalEffect);

// ---------- Renewal Potion ----------
var renewalPotion = new Ingestible(mod.GetNextFormKey(), SkyrimRelease.SkyrimSE)
{
    EditorID = "TR_RenewalPotion",
    Name = "Draught of Renewal",
    Weight = 0.1f,
    Value = 5000,
    Flags = Ingestible.Flag.Medicine,
    Model = new Model
    {
        File = @"Clutter\Potions\PotionFortifyMagickaExtreme.nif",
    },
};
var renewalFx = new Effect
{
    Data = new EffectData { Magnitude = 0f, Area = 0, Duration = 0 }
};
renewalFx.BaseEffect.SetTo(renewalEffect.FormKey);
renewalPotion.Effects.Add(renewalFx);
mod.Ingestibles.Add(renewalPotion);

renewalScript.Properties.Add(Prop("TR_RenewalPotion", renewalPotion.FormKey));

// ---------- Wrapper Leveled List (for SkyPatcher injection) ----------
var renewalPotionLL = new LeveledItem(mod.GetNextFormKey(), SkyrimRelease.SkyrimSE)
{
    EditorID = "TR_RenewalPotionLL",
    ChanceNone = new Noggog.Percent(0.0),
    Flags = LeveledItem.Flag.CalculateForEachItemInCount | LeveledItem.Flag.CalculateFromAllLevelsLessThanOrEqualPlayer,
};
renewalPotionLL.Entries = new Noggog.ExtendedList<LeveledItemEntry>
{
    new LeveledItemEntry
    {
        Data = new LeveledItemEntryData
        {
            Level = 1,
            Count = 1,
            Reference = new FormLink<Mutagen.Bethesda.Skyrim.IItemGetter>(renewalPotion.FormKey),
        },
    },
};
mod.LeveledItems.Add(renewalPotionLL);

Console.WriteLine($"  Wrapper LL    FormKey: {renewalPotionLL.FormKey}");

// ---------- Write output ----------
string outDir = args.Length > 0 ? args[0] : ".";
System.IO.Directory.CreateDirectory(outDir);
string outPath = System.IO.Path.Combine(outDir, "TotalRespec.esp");

mod.WriteToBinary(outPath);
Console.WriteLine($"Wrote: {outPath}");
Console.WriteLine($"  Master potion FormKey: {renewalPotion.FormKey}");

// ---------- Emit SkyPatcher INI for leveled-list injection ----------
string skyPatcherDir = System.IO.Path.Combine(outDir, "SKSE", "Plugins", "SkyPatcher", "leveledList", "TotalRespec");
System.IO.Directory.CreateDirectory(skyPatcherDir);
string llHex = renewalPotionLL.FormKey.ID.ToString("X6");
string iniContent = "; Total Respec - SkyPatcher leveled-list injection\n" +
    "; Wraps TR_RenewalPotion in TR_RenewalPotionLL and injects it into vanilla apothecary lists\n" +
    "; so the Draught of Renewal appears in apothecary inventories (rare, 5000g base value).\n" +
    "\n" +
    "; LItemApothecaryPotionMagicEffects75 - standard apothecary magic-effect potion list\n" +
    "; (used by every major apothecary: Arcadia, Elgrim, Bothela, Hrolthar, etc.)\n" +
    $"filterByLLs=Skyrim.esm|0009CD41:addOnceToLLs=TotalRespec.esp|{llHex}\n";
System.IO.File.WriteAllText(System.IO.Path.Combine(skyPatcherDir, "TotalRespec.ini"), iniContent);
Console.WriteLine($"  SkyPatcher INI:        SKSE/Plugins/SkyPatcher/leveledList/TotalRespec/TotalRespec.ini");
