// A leader challenges the company to a duel before the battle (::ChaosMind.Duel).
this.chaos_mind_duel_event <- this.inherit("scripts/events/event", {
	m = {},

	function create()
	{
		this.m.ID = "event.chaos_mind_duel";
		this.m.Title = "A Challenge";
		this.m.IsSpecial = true;

		this.m.Screens.push({
			ID = "A",
			Text = "[img]gfx/ui/events/event_35.png[/img]"
				+ "Before the lines close, %leader% walks out alone into the open ground between you, weapon raised. Behind him his men bang their shields and roar.\n\n"
				+ "%SPEECH_ON%Send me your best! One of yours against me, and let the gods watch. Or are you all cowards?%SPEECH_OFF%\n\n"
				+ "He carries himself like a man with an army at his back. Every bit of iron his men wear seems to stand behind him.",
			Image = "",
			List = [],
			Characters = [],
			Options = [],

			function start( _event )
			{
				local duel = ::ChaosMind.Duel;
				local c = duel.Current;
				this.Options = [];

				if (c == null)
				{
					this.Options.push({
						Text = "To battle!",
						getResult = @(_event) 0
					});
					return;
				}

				this.List.push({
					id = 10,
					icon = "ui/icons/special.png",
					text = c.LeaderName + " fights the duel with [color=" + ::Const.UI.Color.NegativeValue + "]+" + (c.Buff * 100).tointeger()
						+ "%[/color] to all his combat stats (his men wear " + c.Armor + " armor)"
				});

				local make = function( _i )
				{
					return function( _event )
					{
						return ::ChaosMind.Duel.startDuel(_event, _i);
					};
				};

				foreach (i, bro in c.Candidates)
				{
					this.Options.push({
						Text = "Send " + bro.getName() + " (level " + bro.getLevel() + ").",
						getResult = make(i)
					});
				}

				this.Options.push({
					Text = "Refuse. We fight as a company.",
					getResult = @(_event) "Refused"
				});
			}
		});

		this.m.Screens.push({
			ID = "Refused",
			Text = "[img]gfx/ui/events/event_35.png[/img]"
				+ "You shake your head. %leader% laughs and spits in the dirt, then walks back to his men.\n\n"
				+ "%SPEECH_ON%Then you all die together.%SPEECH_OFF%",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "To battle!",

				function getResult( _event )
				{
					::ChaosMind.Duel.resumeBattle(null);
					return 0;
				}
			}
			],

			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Won",
			Text = "[img]gfx/ui/events/event_87.png[/img]"
				+ "%duelist% stands over the body of %leader%, chest heaving. For a long moment there is no sound at all.\n\n"
				+ "Then the company roars. Across the field, his men look at one another, and you can see the fight going out of them.",
			Image = "",
			List = [],
			Characters = [],
			Options = [],

			function start( _event )
			{
				local duel = ::ChaosMind.Duel;
				duel.removeLeader();
				this.Options = [];

				if (duel.hasMenLeft())
				{
					this.List.push({
						id = 10,
						icon = "ui/icons/morale.png",
						text = "His men start the battle breaking"
					});
					this.Options.push({
						Text = "Charge while they waver!",
						function getResult( _event )
						{
							::ChaosMind.Duel.resumeBattle(::Const.MoraleState.Breaking);
							return 0;
						}
					});
				}
				else
				{
					this.Options.push({
						Text = "It is over.",
						function getResult( _event )
						{
							::ChaosMind.Duel.endWithoutBattle();
							return 0;
						}
					});
				}
			}
		});

		this.m.Screens.push({
			ID = "Lost",
			Text = "[img]gfx/ui/events/event_87.png[/img]"
				+ "%leader% raises his weapon over %duelist% and howls. His men take up the cry, and they come at you with their blood up.",
			Image = "",
			List = [
				{
					id = 10,
					icon = "ui/icons/morale.png",
					text = "His men start the battle confident"
				}
			],
			Characters = [],
			Options = [
			{
				Text = "To arms!",

				function getResult( _event )
				{
					::ChaosMind.Duel.resumeBattle(::Const.MoraleState.Confident);
					return 0;
				}
			}
			],

			function start( _event )
			{
			}
		});

		this.m.Screens.push({
			ID = "Gone",
			Text = "[img]gfx/ui/events/event_35.png[/img]"
				+ "By the time you have chosen, the challenger is nowhere to be seen.",
			Image = "",
			List = [],
			Characters = [],
			Options = [
			{
				Text = "Very well.",

				function getResult( _event )
				{
					::ChaosMind.Duel.Current = null;
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
		return "A";
	}

	function onPrepareVariables( _vars )
	{
		local c = ::ChaosMind.Duel.Current;
		_vars.push([
			"leader",
			c != null ? c.LeaderName : "the leader"
		]);
		_vars.push([
			"duelist",
			(c != null && c.Duelist != null) ? c.Duelist : "your champion"
		]);
	}

	function onClear()
	{
	}
});
