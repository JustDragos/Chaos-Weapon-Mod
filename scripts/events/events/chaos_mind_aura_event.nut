// Aura of 10 (::ChaosMind.Aura): offers the hunt for The Ten near a town, and hands out the amulet.
this.chaos_mind_aura_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.chaos_mind_aura";
		this.m.Title = "Aura of 10";
		this.m.IsSpecial = true;

		this.m.Screens.push({
			ID = "Offer",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "In %town% the talk is all of ten riders. Champions every one of them, the taverners say, sworn to ride together until one of them holds a blade worth the oath.\n\n"
				+ "An old man at the well looks long at Chaos Mind.%SPEECH_ON%They've heard of that one. They wear a medallion between them, gold, and they say whoever holds it never walks alone. Kill all ten and it's yours. If you live.%SPEECH_OFF%\n\n"
				+ "The eye in the crossguard opens. Two hundred and fifty souls, and it wants ten more.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Hunt The Ten.",

				function getResult( _event )
				{
					local party = null;

					try
					{
						party = ::ChaosMind.Aura.spawnTarget();
					}
					catch (e)
					{
						::logError("Chaos Mind: The Ten could not spawn (" + e + ").");
					}

					return party != null ? "Accepted" : "NoSpawn";
				}
			},
			{
				Text = "Not now.",

				function getResult( _event )
				{
					::ChaosMind.Aura.decline();
					return 0;
				}
			}
			],

			function start( _event )
			{
				this.List.push({
					id = 10,
					icon = "ui/icons/kills.png",
					text = "Opened at " + ::ChaosMind.Aura.AuraKills + " Chaos Mind kills"
				});
				this.List.push({
					id = 11,
					icon = "ui/tooltips/warning.png",
					text = "Ten named human champions, all in one party"
				});
				this.List.push({
					id = 12,
					icon = "ui/icons/special.png",
					text = "Reward: Aura of 10, an amulet that makes the company count as ten seasoned men on the map"
				});
			}
		});

		this.m.Screens.push({
			ID = "Accepted",
			Text = "[img]gfx/ui/events/event_143.png[/img]"
				+ "The old man points down the road.%SPEECH_ON%They ride %where%. You'll know them. Ten banners would be quieter.%SPEECH_OFF%",
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
				local names = ::ChaosMind.Aura.ChampionNames;

				if (names != "")
				{
					this.List.push({
						id = 11,
						icon = "ui/icons/kills.png",
						text = "The Ten: " + names
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
				+ "You ride where the old man pointed, but the road is empty and the tracks lead nowhere.\n\n"
				+ "The Ten will be heard of again another day.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Another day, then.",

				function getResult( _event )
				{
					::ChaosMind.Aura.decline();
					return 0;
				}
			}
			],

			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Done",
			Text = "[img]gfx/ui/events/event_140.png[/img]"
				+ "The last of The Ten falls, and the field goes quiet. Around the neck of the first of them, the one who rode in front, hangs a gold medallion, warm as a living thing.\n\n"
				+ "When the wielder lifts it, the air behind him fills with pale shapes. Ten of them, shields up, and they do not go away.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Never alone.",

				function getResult( _event )
				{
					return 0;
				}
			}
			],

			function start( _event )
			{
				local owed = ::World.Flags.has(::ChaosMind.Aura.OwedFlag) && ::World.Flags.get(::ChaosMind.Aura.OwedFlag);
				this.List.push({
					id = 10,
					icon = "ui/items/accessory/aura_of_10.png",
					text = owed ? "Aura of 10 waits until the stash has a free slot" : "You gain Aura of 10"
				});
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
		local a = ::ChaosMind.Aura;
		local screen = a.PendingScreen != null ? a.PendingScreen : "Offer";
		a.PendingScreen = null;
		return screen;
	}

	function onPrepareVariables( _vars )
	{
		local a = ::ChaosMind.Aura;
		local target = a.LastTarget;

		_vars.push([
			"town",
			(a.Town != null && a.Town.isAlive()) ? a.Town.getName() : "the town"
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
