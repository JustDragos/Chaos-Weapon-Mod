// The Devourer's gift: fired once Chaos Mind reaches 100 kills (::ChaosMind.SoulArrow.check).
this.chaos_mind_soul_arrow_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.chaos_mind_soul_arrow";
		this.m.Title = "The Devourer's Gift";
		this.m.IsSpecial = true;

		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "The next time the company stops to rest, the camp goes quiet all at once. The fire burns low and violet, and every man looks up at the same moment towards the blade.\n\n"
				+ "The eye in the crossguard is open. It has fed a hundred times now, and for the first time it seems almost content.\n\n"
				+ "%SPEECH_ON%A hundred souls. I keep what I take... but one I give back. Draw it when you are weak.%SPEECH_OFF%\n\n"
				+ "Something lies on the ground beside the blade that was not there before: a single arrow of pale light, cold to the touch and humming faintly.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Take the Soul Arrow.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
				local arrow = ::ChaosMind.SoulArrow.LastArrow;
				::ChaosMind.SoulArrow.onShown();

				if (arrow != null)
				{
					this.List.push({
						id = 10,
						icon = "ui/items/" + arrow.getIcon(),
						text = "You gain " + arrow.getName() + " (in your stash, for the ammo slot)"
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "StashFull",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "The eye in the crossguard opens and looks over your wagons, heaped with gear.\n\n"
				+ "%SPEECH_ON%I have a gift for you, and nowhere to put it. Make room.%SPEECH_OFF%\n\n"
				+ "Your stash is full. Free a slot and the blade will call again tomorrow.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Later.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
			}
		});
	}

	function onUpdateScore()
	{
	}

	function onPrepare()
	{
	}

	function onDetermineStartScreen()
	{
		local sa = ::ChaosMind.SoulArrow;
		local screen = sa.PendingScreen != null ? sa.PendingScreen : "A";
		sa.PendingScreen = null;
		return screen;
	}

	function onPrepareVariables( _vars )
	{
	}

	function onClear()
	{
	}
});
