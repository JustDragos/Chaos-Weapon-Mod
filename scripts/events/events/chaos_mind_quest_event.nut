// The Black Skull (::ChaosMind.Quest): offers a part of the hunt near a town, and reports it done.
this.chaos_mind_quest_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.chaos_mind_quest";
		this.m.Title = "The Black Skull";
		this.m.IsSpecial = true;

		this.m.Screens.push({
			ID = "Offer",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "Outside %town% a ragged banner has been nailed to a post by the road: black cloth, and a skull painted on it in white. Beneath it a peddler sits on an upturned cart, waiting for you as if he knew you would come.\n\n"
				+ "%SPEECH_ON%They know what you carry. The %party% have come for it, and they make camp not far from here. Their master swears he will be the one to break the blade.%SPEECH_OFF%\n\n"
				+ "At your side the eye in Chaos Mind's crossguard opens, and it is hungry.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Hunt them.",

				function getResult( _event )
				{
					local party = null;

					try
					{
						party = ::ChaosMind.Quest.spawnTarget();
					}
					catch (e)
					{
						::logError("Chaos Mind: the Black Skull could not spawn (" + e + ").");
					}

					return party != null ? "Accepted" : "NoSpawn";
				}
			},
			{
				Text = "Not now.",

				function getResult( _event )
				{
					::ChaosMind.Quest.decline();
					return 0;
				}
			}
			],

			function start( _event )
			{
				local q = ::ChaosMind.Quest;
				local def = q.Tiers[q.getDone()];
				this.List.push({
					id = 10,
					icon = "ui/icons/kills.png",
					text = "Part " + (q.getDone() + 1) + " of 3, opened at " + def.Kills + " kills"
				});
				this.List.push({
					id = 11,
					icon = "ui/icons/fatigue.png",
					text = "Reward: Chaos Mind grants +" + def.Rate + " max fatigue per +1% damage from kills"
				});
				this.List.push({
					id = 12,
					icon = "ui/tooltips/warning.png",
					text = "Their leader must die to Chaos Mind"
				});
			}
		});

		this.m.Screens.push({
			ID = "Accepted",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "The peddler points down the road and is gone before you can pay him.\n\n"
				+ "The %party% are camped %where%. The black skull flies over them, and it will not be hard to find.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Move out.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
				local target = ::ChaosMind.Quest.LastTarget;

				if (target != null && target.isAlive())
				{
					this.List.push({
						id = 11,
						icon = "ui/icons/kills.png",
						text = "The " + ::ChaosMind.Quest.describeTarget(target)
					});
				}

				this.List.push({
					id = 10,
					icon = "ui/icons/special.png",
					text = "They are marked on the map. Press " + ::ChaosMind.getLocateKey() + " to see where they are"
				});
			}
		});

		this.m.Screens.push({
			ID = "NoSpawn",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "You look where the peddler points, but there is nothing there. When you turn back, the post is bare.\n\n"
				+ "The black skull will show itself again another day.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Another day, then.",

				function getResult( _event )
				{
					::ChaosMind.Quest.decline();
					return 0;
				}
			}
			],

			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Failed",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "The %party% are gone, but their master did not die on the blade. The eye in the crossguard stays shut for days, and the wielder sleeps badly.\n\n"
				+ "Somewhere a new black skull is being painted.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Next time, the blade.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
				this.List.push({
					id = 10,
					icon = "ui/icons/kills.png",
					text = "This part of the hunt failed. It will be offered again from tomorrow, in any town"
				});
			}
		});

		this.m.Screens.push({
			ID = "Done",
			Text = "[img]gfx/ui/events/event_140.png[/img]"
				+ "Their master lies dead on the blade and the last of the %party% under their own banner. You pull the black skull down and hold it to the blade, and the cloth blackens and crumbles to ash in your hands.\n\n"
				+ "That night the wielder sleeps like the dead and wakes before dawn, rested as he has never been. The blade has learned to keep him on his feet.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "It grows.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
				local q = ::ChaosMind.Quest;
				local done = q.getDone();
				local def = q.Tiers[done - 1];
				local sword = ::ChaosMind.findSword();
				local text = "Chaos Mind now grants +" + def.Rate + " max fatigue per +1% damage from kills";

				if (sword != null)
				{
					text += " (now +" + q.getStaminaBonus(sword) + ")";
				}

				this.List.push({
					id = 10,
					icon = "ui/icons/fatigue.png",
					text = text
				});

				if (done < q.Tiers.len())
				{
					this.List.push({
						id = 11,
						icon = "ui/icons/kills.png",
						text = "The next black skull rises at " + q.Tiers[done].Kills + " kills"
					});
				}
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
		local q = ::ChaosMind.Quest;
		local screen = q.PendingScreen != null ? q.PendingScreen : "Offer";
		q.PendingScreen = null;
		return screen;
	}

	function onPrepareVariables( _vars )
	{
		local q = ::ChaosMind.Quest;
		local target = q.LastTarget;

		_vars.push([
			"town",
			(q.Town != null && q.Town.isAlive()) ? q.Town.getName() : "the town"
		]);
		_vars.push([
			"party",
			q.PartyName != "" ? q.PartyName : "Black Skull"
		]);
		_vars.push([
			"where",
			(target != null && target.isAlive()) ? ::ChaosMind.Altar.describeLocation(target.getTile()) : "nearby"
		]);
	}

	function onClear()
	{
	}
});
