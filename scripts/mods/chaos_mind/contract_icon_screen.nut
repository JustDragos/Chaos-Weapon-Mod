// Tells ui/mods/chaos_mind/town_contracts.js which contracts are this mod's and which banner each
// gets in the town's contract row. No window of its own. See ::ChaosMind.Contracts.
this.contract_icon_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {},

	function create()
	{
		this.m.ID = "ChaosMindContractIcons";
	}

	function connect()
	{
		this.m.JSHandle = ::UI.connect("ChaosMindContractIcons", this);
	}

	function isConnected()
	{
		return this.m.JSHandle != null;
	}

	// [ { ID, Icon } ]: this mod's contracts and the banner each should show.
	function setIcons( _icons )
	{
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle.asyncCall("setIcons", _icons);
		}
	}
});
