// The Red Dragon as a real contract (::ChaosMind.Contracts): offered by the town the company is in
// once the blade has ::ChaosMind.Dragon.Kills kills, negotiated like any other. Accepting spawns the
// dragon's party near the town (::ChaosMind.Dragon.spawnTarget). Once it is dead, the company
// returns to the town to be paid. It can't fail. Same shape as chaos_mind_aura_contract.
this.chaos_mind_dragon_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Target = null,
		// Set while ::ChaosMind.Contracts rebuilds an accepted contract after loading.
		IsRestoring = false
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.chaos_mind_dragon";
		this.m.Name = "The Red Dragon";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 7.0;

		if ("DescriptionTemplates" in this.m)
		{
			this.m.DescriptionTemplates = [
				"A red dragon has come down from the mountains, and the town is burning at its edges."
			];
		}
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		local d = ::ChaosMind.Dragon;
		this.m.DifficultyMult = d.ContractDifficultyMult;
		this.m.Payment.Pool = d.ContractPay * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		this.m.Payment.Completion = 1.0;
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Slay the Red Dragon near " + this.Contract.m.Home.getName()
				];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				if (this.Contract.m.IsRestoring)
				{
					return;
				}

				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());
				this.Contract.spawnTarget();
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});
		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Slay the Red Dragon near " + this.Contract.m.Home.getName()
				];

				if (this.Contract.m.Target != null && !this.Contract.m.Target.isNull())
				{
					::ChaosMind.markTarget(this.Contract.m.Target);
				}
			}

			function update()
			{
				if (this.Contract.m.Target != null && !this.Contract.m.Target.isNull() && this.Contract.m.Target.isAlive())
				{
					return;
				}

				local d = ::ChaosMind.Dragon;

				if (!this.Flags.has("Spawned"))
				{
					::logWarning("Chaos Mind: the Red Dragon contract had no dragon to hunt; it is dropped.");
					d.decline();
					this.World.Contracts.finishActiveContract(true);
					return;
				}

				this.World.Flags.set(d.StateFlag, 2);
				this.World.Flags.set(d.TargetFlag, 0);
				::logInfo("Chaos Mind: the Red Dragon is slain; its contract is done.");
				this.Contract.setScreen("Victory");
				this.World.Contracts.showActiveContract();
				this.Contract.setState("Return");
			}
		});
		this.m.States.push({
			ID = "Return",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [
					"Return to " + this.Contract.m.Home.getName()
				];
				this.Contract.m.Home.getSprite("selection").Visible = true;
			}

			function update()
			{
				if (this.Contract.isPlayerAt(this.Contract.m.Home))
				{
					this.Contract.setScreen("Success");
					this.World.Contracts.showActiveContract();
				}
			}
		});
	}

	function createScreens()
	{
		this.importScreens(this.Const.Contracts.NegotiationDefault);
		this.importScreens(this.Const.Contracts.Overview);
		this.m.Screens.push({
			ID = "Task",
			Title = "Negotiations",
			Text = "[img]gfx/ui/events/event_143.png[/img]{%employer% doesn't sit. Through the window behind him, smoke still rises over the outlying farms.%SPEECH_ON%A dragon. A red one, big as a barn, with wings that blot out the sun. It burned three farms last night and took the cattle whole.%SPEECH_OFF%He looks at the blade at your side, and for once he doesn't look away.%SPEECH_ON%They say that thing of yours eats whatever it kills. Let it eat this. %reward% crowns, and whatever the beast sleeps on is yours.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{The blade has never tasted dragon. Let's talk pay. | The %companyname% will slay your dragon, for the right price.}",
					function getResult()
					{
						return "Negotiation";
					}
				},
				{
					Text = "{Not now. | Find someone else to feed it.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}
				}
			],
			function start()
			{
				this.List.push({
					id = 10,
					icon = "ui/tooltips/warning.png",
					text = "It takes to the sky, and it breathes fire"
				});
				this.List.push({
					id = 11,
					icon = "ui/icons/asset_money.png",
					text = "Its hoard goes to whoever slays it"
				});
			}
		});
		this.m.Screens.push({
			ID = "Victory",
			Title = "After the battle...",
			Text = "[img]gfx/ui/events/event_140.png[/img]{The dragon is dead. It takes the whole company to lever its head off the ground, and the blade drinks so long from the wound that the wielder has to be pulled away.\n\nIn the ashes of its last fire lie the bones of everything it has eaten, and the gold it slept on. Time to collect the pay in %townname%.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "Back to %townname%.",
					function getResult()
					{
						return 0;
					}
				}
			],
			function start()
			{
			}
		});
		this.m.Screens.push({
			ID = "Success",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_04.png[/img]{%employer% has already heard. Half the town lines the road to see the company come back.%SPEECH_ON%A dragon. They'll sing about this, you know. Badly, but they'll sing.%SPEECH_OFF%He pays in full, and doesn't haggle.}",
			Image = "",
			Characters = [],
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "Dragonslayers.",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess * 2);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Slew the Red Dragon");
						this.World.Contracts.finishActiveContract();
						return 0;
					}
				}
			],
			function start()
			{
				this.List.push({
					id = 10,
					icon = "ui/icons/asset_money.png",
					text = "You gain [color=" + this.Const.UI.Color.PositiveEventValue + "]" + this.Contract.m.Payment.getOnCompletion() + "[/color] Crowns"
				});
			}
		});
	}

	// Accepting: the dragon's party near the town.
	function spawnTarget()
	{
		local d = ::ChaosMind.Dragon;
		d.Town = this.World.getEntityByID(this.m.Home.getID());
		local party = null;

		try
		{
			party = d.spawnTarget();
		}
		catch (e)
		{
			::logError("Chaos Mind: the Red Dragon contract could not spawn the dragon (" + e + ").");
		}

		this.m.Target = party != null ? this.WeakTableRef(party) : null;

		if (party != null)
		{
			this.m.Flags.set("Spawned", true);
		}
	}

	// After loading: the party the hunt is after.
	function relinkTarget()
	{
		local party = ::ChaosMind.Dragon.getTarget();
		this.m.Target = party != null ? this.WeakTableRef(party) : null;
		this.m.Flags.set("Spawned", true);
	}

	function onClear()
	{
		if (this.m.IsActive && this.m.Home != null && !this.m.Home.isNull())
		{
			this.m.Home.getSprite("selection").Visible = false;
		}
	}

	function onIsValid()
	{
		if (this.m.IsActive || this.m.IsRestoring)
		{
			return true;
		}

		return ::ChaosMind.Dragon.isOpen();
	}

	function onSerialize( _out )
	{
		_out.writeU32(this.m.Target != null && !this.m.Target.isNull() ? this.m.Target.getID() : 0);
		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		local target = _in.readU32();

		if (target != 0)
		{
			this.m.Target = this.WeakTableRef(this.World.getEntityByID(target));
		}

		this.contract.onDeserialize(_in);
	}
});
