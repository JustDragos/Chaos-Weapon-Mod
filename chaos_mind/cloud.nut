::ChaosMind.CloudParticles <- null;


// Picks the darkest particle set the game has for the Chaos Mind cloud.
// The names aren't documented, so try likely ones and log what exists if none match.
::ChaosMind.getCloudParticles <- function()
{
    if (::ChaosMind.CloudParticles != null)
    {
        return ::ChaosMind.CloudParticles.len() == 0 ? null : ::ChaosMind.CloudParticles;
    }

    local candidates = [
        "DarkflightStartParticles",
        "DarkflightEndParticles",
        "SmokeParticles",
        "MiasmaParticles"
    ];

    foreach (name in candidates)
    {
        if (name in ::Const.Tactical)
        {
            ::logInfo("Chaos Mind: cloud uses ::Const.Tactical." + name);
            ::ChaosMind.CloudParticles = ::Const.Tactical[name];
            return ::ChaosMind.CloudParticles;
        }
    }

    local available = "";

    foreach (key, _ in ::Const.Tactical)
    {
        if (key.find("Particles") != null)
        {
            available += (available == "" ? "" : ", ") + key;
        }
    }

    ::logWarning("Chaos Mind: No cloud particles found. Available: " + (available == "" ? "none" : available));
    ::ChaosMind.CloudParticles = [];
    return null;
};
