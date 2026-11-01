::ChaosMind <- {
    ID = "mod_chaos_mind",
    Version = "1.0.0",
    Name = "Chaos Mind"
};

local mod = ::Hooks.register(
    ::ChaosMind.ID,
    ::ChaosMind.Version,
    ::ChaosMind.Name
);

::ChaosMind.HooksMod <- mod;

mod.require("mod_msu >= 1.2.0 (Modding Standards & Utilities)");

mod.queue(">mod_msu", function()
{
    ::ChaosMind.Mod <- ::MSU.Class.Mod(
        ::ChaosMind.ID,
        ::ChaosMind.Version,
        ::ChaosMind.Name
    );

    ::include("chaos_mind/common");
    ::include("chaos_mind/cloud");
    ::include("chaos_mind/notice");
    ::include("chaos_mind/carnal_storage");
    ::include("chaos_mind/altar");
    ::include("chaos_mind/only_chaos_matters");
    ::include("chaos_mind/chaos_armor");
    ::include("chaos_mind/chaos_protection");
    ::include("chaos_mind/fatigue_transfer");
    ::include("chaos_mind/chaos_circle");
    ::include("chaos_mind/soul_arrow");
    ::include("chaos_mind/armor_fixer");
    ::include("chaos_mind/used_to_it");
    ::include("chaos_mind/duel");
    ::include("chaos_mind/guide");
    ::include("chaos_mind/quest");
    ::include("chaos_mind/hooks/world_state");
});
