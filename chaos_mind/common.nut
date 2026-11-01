// Shared by the mod's modules: the sword's ID, finding the company's sword, hotkey text, the
// in-game hour, and one world-map hook (asset_manager.update) that runs every module's regular check.
::ChaosMind.SwordID <- "weapon.chaos_mind";

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
