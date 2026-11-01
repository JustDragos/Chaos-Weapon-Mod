// Squirrel side of the brother-picker window at The Frozen Eye (ui/mods/chaos_mind/altar.js).
this.altar_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {},

	function create()
	{
		this.m.ID = "ChaosMindAltarScreen";
	}

	function connect()
	{
		this.m.JSHandle = ::UI.connect("ChaosMindAltarScreen", this);
	}

	function show( _data )
	{
		if (this.m.JSHandle == null)
		{
			::logError("Chaos Mind: altar window is not connected.");
			return;
		}

		this.m.JSHandle.asyncCall("show", _data);
	}

	function hide()
	{
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle.asyncCall("hide", null);
		}
	}

	function onOfferPressed( _ids )
	{
		::ChaosMind.Altar.offer(_ids);
	}

	function onClosePressed()
	{
		::ChaosMind.Altar.closePicker();
	}
});
