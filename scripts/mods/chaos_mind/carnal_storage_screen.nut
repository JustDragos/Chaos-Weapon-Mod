// Squirrel side of the Carnal Storage window (ui/mods/chaos_mind/carnal_storage.js).
this.carnal_storage_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {},

	function create()
	{
		this.m.ID = "CarnalStorageScreen";
	}

	function connect()
	{
		this.m.JSHandle = ::UI.connect("CarnalStorageScreen", this);
	}

	function show( _data )
	{
		if (this.m.JSHandle == null)
		{
			::logError("Chaos Mind: Carnal Storage window is not connected.");
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

	function update( _data )
	{
		if (this.m.JSHandle != null)
		{
			this.m.JSHandle.asyncCall("updateData", _data);
		}
	}

	function onSacrificePressed( _data )
	{
		::ChaosMind.CarnalStorage.sacrifice(_data.Mode, _data.Amount);
	}

	function onUnleashPressed()
	{
		::ChaosMind.CarnalStorage.unleash();
	}

	function onClosePressed()
	{
		::ChaosMind.CarnalStorage.close();
	}

});
