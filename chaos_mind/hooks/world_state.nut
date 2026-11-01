// The Frozen Eye appears on new campaigns, and on loading older campaigns that lack it.
::ChaosMind.HooksMod.hook("scripts/states/world_state", function(q)
{
    q.startNewCampaign = @(__original) function()
    {
        __original();
        ::ChaosMind.Altar.spawn();
    }

    q.loadCampaign = @(__original) function( _campaignFileName )
    {
        __original(_campaignFileName);
        ::ChaosMind.Altar.spawn();
    }
});
