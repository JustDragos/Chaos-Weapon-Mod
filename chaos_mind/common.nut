// Shared by the mod's modules: the sword's ID, finding the company's sword, hotkey text, the
// in-game hour, and one world-map hook (asset_manager.update) that runs every module's regular check.
::ChaosMind.SwordID <- "weapon.chaos_mind";
// Armor penetration on top of the greatsword's (DirectDamageMult: the share of damage that goes
// past armor to hitpoints). Added 13 Nov.
::ChaosMind.ArmorPenetrationBonus <- 0.2;

::ChaosMind.isSword <- function( _item )
{
    return _item != null && _item.getID() == ::ChaosMind.SwordID;
};

// The company's Chaos Mind: in a brother's hands first, then in the stash. With _filter, only a
// sword it accepts (e.g. @(_s) _s.isDevourer()).
::ChaosMind.findSword <- function( _filter = null )
{
    foreach (bro in ::World.getPlayerRoster().getAll())
    {
        local weapon = bro.getMainhandItem();

        if (::ChaosMind.isSword(weapon) && (_filter == null || _filter(weapon)))
        {
            return weapon;
        }
    }

    foreach (item in ::World.Assets.getStash().getItems())
    {
        if (::ChaosMind.isSword(item) && (_filter == null || _filter(item)))
        {
            return item;
        }
    }

    return null;
};

// The keys bound to one of this mod's keybinds, as Mod Settings shows them.
::ChaosMind.getHotkey <- function( _id, _default )
{
    try
    {
        local keys = ::ChaosMind.Mod.Keybinds.getKeybind(_id).getKeyCombinationsCapitalized();

        if (keys != "")
        {
            return keys;
        }
    }
    catch (e)
    {
    }

    return _default;
};

// Ctrl+G: the Chaos Guide (chaos_mind/guide.nut).
::ChaosMind.getGuideKey <- function()
{
    return ::ChaosMind.getHotkey("openChaosGuide", "Ctrl+G");
};

// Ctrl+F: The Frozen Eye, then the Black Skull's marked party (chaos_mind/altar.nut).
::ChaosMind.getLocateKey <- function()
{
    return ::ChaosMind.getHotkey("showFrozenEyeDirection", "Ctrl+F");
};

// A party the company is sent to hunt (Black Skull, The Ten, Army of the Past): shown on the map
// from anywhere, through the fog of war, like a vanilla contract's target (setVisibleInFogOfWar,
// as in decisive_battle and raid_caravan), with its selection ring. Added 14 Nov ("they spawn at
// random"). Each call guarded.
::ChaosMind.markTarget <- function( _party )
{
    if (_party == null || !_party.isAlive())
    {
        return;
    }

    // The three calls vanilla's decisive_battle and raid_caravan contracts make on their targets
    // (Legends copies). setVisibleInFogOfWar alone wasn't enough (14 Nov): a party the player
    // hasn't discovered yet isn't drawn at all, so setDiscovered shows it from the start.
    local steps = [
        [ "setVisibleInFogOfWar", @(_p) _p.setVisibleInFogOfWar(true) ],
        [ "setImportant", @(_p) _p.setImportant(true) ],
        [ "setDiscovered", @(_p) _p.setDiscovered(true) ],
        [ "selection ring", function( _p ) { _p.getSprite("selection").Visible = true; } ]
    ];

    foreach (step in steps)
    {
        try
        {
            step[1](_party);
        }
        catch (e)
        {
            if (!(step[0] in ::ChaosMind.MarkTargetWarned))
            {
                ::ChaosMind.MarkTargetWarned[step[0]] <- true;
                ::logWarning("Chaos Mind: a hunt target got no " + step[0] + " (" + e + ").");
            }
        }
    }
};

::ChaosMind.MarkTargetWarned <- {};

// In-game hours since the campaign began, for once-an-hour checks.
::ChaosMind.getHour <- function()
{
    local time = ::World.getTime();
    return time.Days * 24 + time.Hours;
};

// Regular world-map checks, run in the order added on every asset_manager.update. Each throttles
// itself. A failing check is logged once, not on every update.
::ChaosMind.WorldChecks <- [];

::ChaosMind.addWorldCheck <- function( _name, _check )
{
    ::ChaosMind.WorldChecks.push({ Name = _name, Check = _check, Warned = false });
};

::ChaosMind.HooksMod.hook("scripts/states/world/asset_manager", function(q)
{
    q.update = @(__original) function( _worldState )
    {
        local ret = __original(_worldState);

        foreach (c in ::ChaosMind.WorldChecks)
        {
            try
            {
                c.Check();
            }
            catch (e)
            {
                if (!c.Warned)
                {
                    c.Warned = true;
                    ::logWarning("Chaos Mind: " + c.Name + " failed (" + e + "); later failures aren't logged.");
                }
            }
        }

        return ret;
    }
});
