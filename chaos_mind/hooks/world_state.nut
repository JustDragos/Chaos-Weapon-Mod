// The Frozen Eye appears on new campaigns, and on loading older campaigns that lack it.
// Saving and loading also go through ::ChaosMind.SaveSafety, so saves load without the mod.
::ChaosMind.HooksMod.hook("scripts/states/world_state", function(q)
{
    q.startNewCampaign = @(__original) function()
    {
        __original();
        ::ChaosMind.Contracts.reset();

        // Starting brothers' given levels get the leveling settings too (chaos_mind/settings.nut).
        try
        {
            ::ChaosMind.Settings.onNewCampaign();
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: the leveling settings could not be applied to the starting brothers (" + e + ").");
        }

        ::ChaosMind.Altar.spawn();
    }

    q.loadCampaign = @(__original) function( _campaignFileName )
    {
        __original(_campaignFileName);
        ::ChaosMind.Contracts.reset();

        try
        {
            ::ChaosMind.SaveSafety.bringBack();
        }
        catch (e)
        {
            ::logError("Chaos Mind: could not bring back the items and perks kept in the save (" + e + ").");
        }

        try
        {
            ::ChaosMind.Army.repairWrongDone();
        }
        catch (e)
        {
        }

        ::ChaosMind.Altar.spawn();
    }

    // The whole save is written inside this call (MSU relies on the same), so this mod's things are
    // only out of the world while it runs. Only with the Saves setting on (off by default).
    q.saveCampaign = @(__original) function( _campaignFileName, _campaignLabel = null )
    {
        try
        {
            ::ChaosMind.Altar.cleanFallen();
        }
        catch (e)
        {
            ::logWarning("Chaos Mind: could not check the obituary before saving (" + e + ").");
        }

        if (!::ChaosMind.Settings.isSaveSafetyOn())
        {
            return __original(_campaignFileName, _campaignLabel);
        }

        local safety = ::ChaosMind.SaveSafety;

        try
        {
            local count = safety.takeOut();

            if (!safety.FirstSaveLogged)
            {
                safety.FirstSaveLogged = true;
                ::logInfo("Chaos Mind: saving with " + count + " item(s) and perk(s) kept in flags, so the save loads without the mod.");
            }
        }
        catch (e)
        {
            ::logError("Chaos Mind: could not take everything out for the save (" + e + "); this save may still need the mod.");
        }

        try
        {
            __original(_campaignFileName, _campaignLabel);
        }
        catch (e)
        {
            safety.putBack();
            throw e;
        }

        safety.putBack();
    }
});
