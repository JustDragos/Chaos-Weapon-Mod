// The Frozen Eye. Also shows the result of an offering (::ChaosMind.Altar.fireEvent).
this.chaos_mind_altar_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.location.chaos_mind_altar";
		this.m.Title = "The Frozen Eye";
		this.m.IsSpecial = true;

		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_28.png[/img]"
				+ "A greatsword stands buried point-first in the ice, black as a hole in the world. The snow around it is stained violet, and no wind touches it.\n\n"
				+ "In the crossguard an eye opens and finds you. Its voice is in every man's head at once, patient and hungry.\n\n"
				+ "%SPEECH_ON%Eight. Eight lives, freely given, and I am yours.%SPEECH_OFF%",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Offer eight brothers to the eye.",

				function getResult( _event )
				{
					if (!::ChaosMind.Altar.canOffer())
					{
						return "NotEnough";
					}

					::ChaosMind.Altar.openPicker();
					return 0;
				}
			},
			{
				Text = "Not now.",

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

		this.m.Screens.push({
			ID = "NotEnough",
			Text = "[img]gfx/ui/events/event_28.png[/img]"
				+ "The eye looks over the company and closes again, unimpressed.\n\n"
				+ "%SPEECH_ON%You cannot spare what I ask. Come back with more men.%SPEECH_OFF%\n\n"
				+ "You need at least %required% brothers who can be offered, and someone must be left to carry the blade. You have %eligible% who can be offered.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Leave.",

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

		this.m.Screens.push({
			ID = "Offered",
			Text = "[img]gfx/ui/events/event_140.png[/img]"
				+ "The chosen walk to the blade one by one. None of them run. When the last of them falls, the ice cracks and the greatsword slides free into your hands, warm as a living thing.\n\n"
				+ "The rest of the company will not meet your eyes for a long time.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Take Chaos Mind.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
				local altar = ::ChaosMind.Altar;

				if (altar.LastSword != null)
				{
					this.List.push({
						id = 10,
						icon = "ui/items/" + altar.LastSword.getIcon(),
						text = "You gain " + altar.LastSword.getName()
					});
				}

				if (altar.LastGuide != null)
				{
					this.List.push({
						id = 10,
						icon = "ui/items/" + altar.LastGuide.getIcon(),
						text = "You gain " + altar.LastGuide.getName()
					});
				}

				foreach (name in altar.LastSacrificed)
				{
					this.List.push({
						id = 11,
						icon = "ui/icons/kills.png",
						text = name + " has been sacrificed"
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "StashFull",
			Text = "[img]gfx/ui/events/event_28.png[/img]"
				+ "The eye watches your overloaded wagons with something like amusement.\n\n"
				+ "%SPEECH_ON%And where would you carry me? Make room first.%SPEECH_OFF%\n\n"
				+ "Free a slot in your stash. No one was sacrificed.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Leave.",

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

		this.m.Screens.push({
			ID = "Claimed",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "Only a cracked hollow in the ice remains where the blade once stood. The snow around it is still faintly violet.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Leave.",

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
		local altar = ::ChaosMind.Altar;

		if (altar.PendingScreen != null)
		{
			local screen = altar.PendingScreen;
			altar.PendingScreen = null;
			return screen;
		}

		return altar.isClaimed() ? "Claimed" : "A";
	}

	function onPrepareVariables( _vars )
	{
		_vars.push([
			"required",
			::ChaosMind.Altar.RequiredSacrifices
		]);

		_vars.push([
			"eligible",
			::ChaosMind.Altar.getEligible().len()
		]);
	}

	function onClear()
	{
	}
});
