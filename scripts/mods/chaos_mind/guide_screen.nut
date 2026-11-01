// Squirrel side of the Chaos Guide window (ui/mods/chaos_mind/guide.js).
this.guide_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {
		IsShowing = false
	},

	function create()
	{
		this.m.ID = "ChaosMindGuideScreen";
	}

	function connect()
	{
		this.m.JSHandle = ::UI.connect("ChaosMindGuideScreen", this);
	}

	function isShowing()
	{
		return this.m.IsShowing;
	}

	function show( _data )
	{
		if (this.m.JSHandle == null)
		{
			::logError("Chaos Mind: Chaos Guide window is not connected.");
			return;
		}

		this.m.IsShowing = true;
		this.m.JSHandle.asyncCall("show", _data);
	}

	function hide()
	{
		this.m.IsShowing = false;

		if (this.m.JSHandle != null)
		{
			this.m.JSHandle.asyncCall("hide", null);
		}
	}

	function onClosePressed()
	{
		this.hide();
	}
});
