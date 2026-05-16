Scriptname TR_RenewalEffect extends ActiveMagicEffect
{Total Respec - one-shot character reset using Skyrim's native level-up system.

Flow on potion drink:
  1. Confirm modal: Continue or Back (returns the potion to inventory).
  2. Refund every perk via SKSE GetPerkTree introspection.
  3. Drop player to level 1, XP 0.
  4. Set base H/M/S/CW to the JSON baselines (so level-ups start from the right floor).
  5. Restore the player's original XP - Skyrim queues all the level-ups in rapid succession.
  6. Player allocates each attribute point via the standard Skills > Level Up choice screen,
     which is Skyrim's robust engine-native way to permanently modify base AVs.

In Survival Mode the level-up menu only becomes available after sleeping.}

Message Property TR_ConfirmMsg Auto
Potion Property TR_RenewalPotion Auto
FormList Property TR_PerkWorkingList Auto

String Property CONFIG_PATH = "Data/SKSE/Plugins/TotalRespec.json" AutoReadOnly

Int perkCount

Function RefundPerksForTree(String avName, Actor akTarget)
    TR_PerkWorkingList.Revert()
    ActorValueInfo avInfo = ActorValueInfo.GetActorValueInfoByName(avName)
    If avInfo
        avInfo.GetPerkTree(TR_PerkWorkingList, akTarget, False, True)
        Int i = 0
        Int sz = TR_PerkWorkingList.GetSize()
        While i < sz
            Perk p = TR_PerkWorkingList.GetAt(i) as Perk
            If p && akTarget.HasPerk(p)
                akTarget.RemovePerk(p)
                perkCount += 1
            EndIf
            i += 1
        EndWhile
    EndIf
    TR_PerkWorkingList.Revert()
EndFunction

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If akTarget != Game.GetPlayer()
        Return
    EndIf

    If SKSE.GetVersion() < 1
        Debug.MessageBox("Total Respec requires SKSE64.")
        Return
    EndIf

    ; --- Step 1: confirm ---
    Int confirm = TR_ConfirmMsg.Show(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
    If confirm != 0
        akTarget.AddItem(TR_RenewalPotion, 1, True)
        Debug.Notification("Renewal canceled. Potion returned to inventory.")
        Return
    EndIf

    ; --- Step 2: load baselines from JSON config ---
    Int cfg = JValue.readFromFile(CONFIG_PATH)
    Float baseH  = JMap.getFlt(cfg, "baselineHealth",      100.0)
    Float baseM  = JMap.getFlt(cfg, "baselineMagicka",     100.0)
    Float baseS  = JMap.getFlt(cfg, "baselineStamina",     100.0)
    Float baseCW = JMap.getFlt(cfg, "baselineCarryWeight", 300.0)

    ; --- Step 3: capture XP so we can restore it after the level reset ---
    Int playerLv = akTarget.GetLevel()
    Float currLvExp = Game.GetPlayerExperience()
    Float levelUpBase = Game.GetGameSettingFloat("fXPLevelUpBase")
    Float levelUpMult = Game.GetGameSettingFloat("fXPLevelUpMult")
    Float playerLvF = playerLv as Float
    Float totalExp = (playerLvF - 1.0) * levelUpBase + (levelUpMult * (playerLvF - 2.0) * (playerLvF + 1.0)) / 2.0 + levelUpMult + currLvExp

    ; --- Step 4: refund all perks ---
    perkCount = 0
    RefundPerksForTree("Alchemy",     akTarget)
    RefundPerksForTree("Alteration",  akTarget)
    RefundPerksForTree("Marksman",    akTarget)
    RefundPerksForTree("Block",       akTarget)
    RefundPerksForTree("Conjuration", akTarget)
    RefundPerksForTree("Destruction", akTarget)
    RefundPerksForTree("Enchanting",  akTarget)
    RefundPerksForTree("HeavyArmor",  akTarget)
    RefundPerksForTree("Illusion",    akTarget)
    RefundPerksForTree("LightArmor",  akTarget)
    RefundPerksForTree("Lockpicking", akTarget)
    RefundPerksForTree("OneHanded",   akTarget)
    RefundPerksForTree("Pickpocket",  akTarget)
    RefundPerksForTree("Restoration", akTarget)
    RefundPerksForTree("Smithing",    akTarget)
    RefundPerksForTree("Sneak",       akTarget)
    RefundPerksForTree("Speechcraft", akTarget)
    RefundPerksForTree("TwoHanded",   akTarget)
    ; Refund the perks we just removed, but COMPENSATE for the (playerLv - 1) perk points
    ; the engine will hand out on its own when the player accepts each level-up below.
    ; Net grant here: perkCount - (playerLv - 1). For a vanilla character this is 0;
    ; for a character with bonus perks (Oghma Infinium etc.) the bonus is preserved.
    Game.ModPerkPoints(perkCount - (playerLv - 1))

    ; --- Step 5: lock player controls while we juggle level state ---
    Game.DisablePlayerControls(False, False, False, False, False, True, False, False, 0)

    ; --- Step 6: drop level + XP to vanilla level 1 (matches the proven Potion-of-Reset pattern) ---
    Game.SetPlayerExperience(0.0)
    Game.SetPlayerLevel(1)

    ; --- Step 7: set base AVs to the JSON baselines so level-ups start from the right floor ---
    akTarget.SetActorValue("Health",      baseH)
    akTarget.SetActorValue("Magicka",     baseM)
    akTarget.SetActorValue("Stamina",     baseS)
    akTarget.SetActorValue("CarryWeight", baseCW)

    ; --- Step 8: let the engine commit the level-1 state ---
    Utility.Wait(2.0)

    ; --- Step 9: restore XP -> Skyrim queues all the level-ups in sequence ---
    Game.SetPlayerExperience(totalExp)

    ; --- Step 10: small settle pause, then re-enable input ---
    Utility.Wait(1.0)
    Game.EnablePlayerControls()

    ; --- Step 10b: deterministically set base CarryWeight to the formula value.
    ; Don't trust whatever the engine ended up with - just compute what it should be from the
    ; JSON baseline + the player's Stamina picks (+5 CW per Stamina level-up choice) and force
    ; the base to that exact value. This is robust against:
    ;   - Survival Mode suppressing the per-Stamina +5 CW bonus during synthetic level-ups
    ;   - Equipped enchanted gear / Steed Stone / Extra Pockets (these are modifiers on top of
    ;     base, so GetBaseActorValue already ignores them - we set the BASE, not effective)
    ;   - Any other engine state we'd rather not depend on
    Float postStamina = akTarget.GetBaseActorValue("Stamina")
    Float staminaPicks = (postStamina - baseS) / 10.0
    If staminaPicks < 0.0
        staminaPicks = 0.0
    EndIf
    Float expectedCW = baseCW + staminaPicks * 5.0
    Float currentBaseCW = akTarget.GetBaseActorValue("CarryWeight")
    Float cwDelta = expectedCW - currentBaseCW
    If cwDelta != 0.0
        akTarget.ModActorValue("CarryWeight", cwDelta)
    EndIf

    ; --- Step 11: summary popup ---
    Int attrCount = playerLv - 1
    If attrCount < 0
        attrCount = 0
    EndIf
    Debug.MessageBox(perkCount + " perks refunded. Base reset to H:" + (baseH as Int) + " M:" + (baseM as Int) + " S:" + (baseS as Int) + " CW:" + (baseCW as Int) + ". " + attrCount + " level-up(s) queued. Open Skills menu and click 'Level Up!' " + attrCount + " times to allocate H/M/S the vanilla way.\n\nIf you use Survival Mode: the level-up menu is gated behind sleeping. Sleep in a bed to access it.")
EndEvent
