// Troll Allegiance (tier 3 perk, perk.troll_allegiance): all his recovery is 20% stronger.
//  - In battle: the fatigue he recovers each turn (FatigueRecoveryRate, raised in the perk's
//    onAfterUpdate so other bonuses count too) and this mod's healing (Vampire Allegiance).
//  - On the world map, once an hour like the game's own healing: 20% of the game's hourly hitpoint
//    healing on top, and his temporary injuries heal 20% faster (the time they were taken is moved
//    back by 0.2 hours per hour, only while there's medicine to heal them).
// Names from More Perks (Rebound) and the Legends source; the game's own scripts are encrypted.
::ChaosMind.TrollAllegiance <- {
    PerkID = "perk.troll_allegiance",
    RecoveryMult = 1.2,
    LastHour = null,
    HitpointRemainders = {},
    FirstHealLogged = false,

    function has( _actor )
    {
        return _actor != null && _actor.getSkills().hasSkill(this.PerkID);
    }

    // A heal from this mod, made stronger if _actor has the perk.
    function boostHeal( _actor, _amount )
    {
        return this.has(_actor) ? ::Math.round(_amount * this.RecoveryMult) : _amount;
    }

    function check()
    {
        local hour = ::ChaosMind.getHour();

        // The first check after loading only notes the hour.
        if (this.LastHour == null || hour <= this.LastHour)
        {
            this.LastHour = hour;
            return;
        }

        local hours = ::Math.min(24, hour - this.LastHour);
        this.LastHour = hour;

        if (("IsConsumingAssets" in ::World.Assets.m) && !::World.Assets.m.IsConsumingAssets)
        {
            return;
        }

        local extra = this.RecoveryMult - 1.0;
        local hitpointsPerHour = ::Const.World.Assets.HitpointsPerHour * ::World.Assets.m.HitpointsPerHourMult;

        try
        {
            hitpointsPerHour *= ::Const.Difficulty.HealMult[::World.Assets.getEconomicDifficulty()];
        }
        catch (e)
        {
        }

        foreach (bro in ::World.getPlayerRoster().getAll())
        {
            if (!this.has(bro))
            {
                continue;
            }

            this.healHitpoints(bro, hitpointsPerHour * extra * hours);

            if (::World.Assets.getMedicine() > 0)
            {
                local shift = ::World.getTime().SecondsPerDay / 24.0 * extra * hours;

                foreach (injury in bro.getSkills().query(::Const.SkillType.TemporaryInjury))
                {
                    if ("TimeApplied" in injury.m)
                    {
                        injury.m.TimeApplied -= shift;
                    }
                }
            }
        }
    }

    // Hitpoints may be whole numbers only, so fractions are saved up per brother until they make 1.
    function healHitpoints( _bro, _amount )
    {
        local id = _bro.getID();
        local missing = _bro.getHitpointsMax() - _bro.getHitpoints();

        if (missing <= 0)
        {
            this.HitpointRemainders[id] <- 0.0;
            return;
        }

        local total = _amount + (id in this.HitpointRemainders ? this.HitpointRemainders[id] : 0.0);
        local whole = ::Math.min(missing, ::Math.floor(total));
        this.HitpointRemainders[id] <- total - ::Math.floor(total);

        if (whole <= 0)
        {
            return;
        }

        _bro.setHitpoints(_bro.getHitpoints() + whole);

        if (!this.FirstHealLogged)
        {
            this.FirstHealLogged = true;
            ::logInfo("Chaos Mind: Troll Allegiance healed " + _bro.getName() + " for " + whole + " extra on the world map.");
        }
    }
};

::Const.Strings.PerkName.TrollAllegiance <- "Troll Allegiance";
::Const.Strings.PerkDescription.TrollAllegiance <- "Something of the troll's flesh has taken root in him. All his recovery is [color="
    + ::Const.UI.Color.PositiveValue + "]+20%[/color]: fatigue recovered each turn in battle, hitpoints healed on the world map, "
    + "injuries healing, and healing from Vampire Allegiance.";

local trollAllegiancePerk = {
    ID = "perk.troll_allegiance",
    Script = "scripts/skills/perks/perk_troll_allegiance",
    Name = ::Const.Strings.PerkName.TrollAllegiance,
    Tooltip = ::Const.Strings.PerkDescription.TrollAllegiance,
    Icon = "skills/chaos_mind/troll_allegiance.png",
    IconDisabled = "skills/chaos_mind/troll_allegiance_sw.png",
    Row = 2,
    Unlocks = 2
};
::Const.Perks.Perks[2].push(trollAllegiancePerk);
::Const.Perks.LookupMap[trollAllegiancePerk.ID] <- trollAllegiancePerk;

::ChaosMind.addWorldCheck("Troll Allegiance check", function()
{
    ::ChaosMind.TrollAllegiance.check();
});
