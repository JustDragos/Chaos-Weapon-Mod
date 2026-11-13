// The Black Skull as a real contract (::ChaosMind.Contracts): offered by the town the company is in
// once the next part is open, negotiated like any other. Accepting spawns the marked party
// (::ChaosMind.Quest.spawnTarget). Its leader must die to Chaos Mind: then the part is done (more
// max fatigue at once) and the company returns to the town to be paid. If the party is gone and the
// leader didn't die to the blade, the contract fails and the part is offered again tomorrow.
// Built on the readable Legends contract legend_hunting_mummies_contract.
this.chaos_mind_black_skull_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Target = null,
		// Set while ::ChaosMind.Contracts rebuilds an accepted contract after loading.
		IsRestoring = false
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.chaos_mind_black_skull";
		this.m.Name = "The Black Skull";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 7.0;

		if ("DescriptionTemplates" in this.m)
		{
			this.m.DescriptionTemplates = [
				"A band under a black skull banner has come for the blade you carry. The town wants them gone."
			];
		}
	}

	function getTier()
	{
		return this.m.Flags.has("Tier") ? this.m.Flags.get("Tier") : ::ChaosMind.Quest.getDone() + 1;
	}

	function getDef()
	{
		local q = ::ChaosMind.Quest;
		return q.Tiers[::Math.min(q.Tiers.len(), this.getTier()) - 1];
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		local def = this.getDef();
		this.m.DifficultyMult = def.DifficultyMult;
		this.m.Payment.Pool = def.Pay * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
		this.m.Payment.Completion = 1.0;
		this.contract.start();
	}

	function createStates()
	{
		this.m.States.push({
			ID = "Offer",
			function start()
			{
				local def = this.Contract.getDef();
				this.Contract.m.BulletpointsObjectives = [
					"Hunt down the " + def.Name + " around " + this.Contract.m.Home.getName(),
					"Their leader must die to Chaos Mind"
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
				this.Flags.set("Tier", ::ChaosMind.Quest.getDone() + 1);
				this.Contract.spawnTarget();
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});
		this.m.States.push({
			ID = "Running",
			function start()
			{
				local def = this.Contract.getDef();
				this.Contract.m.BulletpointsObjectives = [
					"Hunt down the " + def.Name + " around " + this.Contract.m.Home.getName(),
					"Their leader must die to Chaos Mind"
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

				local q = ::ChaosMind.Quest;

				if (!this.Flags.has("Spawned"))
				{
					::logWarning("Chaos Mind: the Black Skull contract had no party to hunt; it is dropped.");
					q.decline();
					this.World.Contracts.finishActiveContract(true);
					return;
				}

				local tier = this.Contract.getTier();
				local slain =this.World.Flags.has(q.LeaderSlainFlag) && this.World.Flags.get(q.LeaderSlainFlag);
				q.clearHunt();

				if (slain)
				{
					this.World.Flags.set(q.DoneFlag, tier);
					::logInfo("Chaos Mind: the Black Skull (part " + tier + ") is done by contract.");
					this.Contract.setScreen("Victory");
					this.World.Contracts.showActiveContract();
					this.Contract.setState("Return");
				}
				else
				{
					this.World.Flags.set(q.DeclinedDayFlag, this.World.getTime().Days);
					::logInfo("Chaos Mind: the Black Skull (part " + tier + ") contract failed: the leader didn't die to the blade.");
					this.Contract.setScreen("Failure");
					this.World.Contracts.showActiveContract();
				}
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
			Text = "[img]gfx/ui/events/event_143.png[/img]{%employer% has a ragged banner spread over his table: black cloth, a skull painted on it in white.%SPEECH_ON%They nailed this to a post outside our walls. The %party%. They make camp not far from here, and they say their master will break the blade you carry.%SPEECH_OFF%He glances at Chaos Mind and quickly away again.%SPEECH_ON%I don't care about your sword. I care that they're scaring off every trader on the road. Kill them, and kill their master, and %reward% crowns are yours.%SPEECH_OFF%At your side the eye in the crossguard opens, and it is hungry.}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{The blade wants their master anyway. Let's talk pay. | The %companyname% can do this, for the right price.}",
					function getResult()
					{
						return "Negotiation";
					}
				},
				{
					Text = "{Not now. | We'll deal with them another time.}",
					function getResult()
					{
						this.World.Contracts.removeContract(this.Contract);
						return 0;
					}
				}
			],
			function start()
			{
				local def = this.Contract.getDef();
				this.List.push({
					id = 10,
					icon = "ui/icons/fatigue.png",
					text = "Part " + this.Contract.getTier() + " of " + ::ChaosMind.Quest.Tiers.len() + ". Also: Chaos Mind grants +" + def.Rate + " max fatigue per +1% damage from kills"
				});
				this.List.push({
					id = 11,
					icon = "ui/tooltips/warning.png",
					text = "Their leader must die to Chaos Mind"
				});
			}
		});
		this.m.Screens.push({
			ID = "Victory",
			Title = "After the battle...",
			Text = "[img]gfx/ui/events/event_140.png[/img]{Their master lies dead on the blade and the last of the %party% under their own banner. You pull the black skull down and hold it to the blade, and the cloth blackens and crumbles to ash in your hands.\n\nThat night the wielder sleeps like the dead and wakes before dawn, rested as he has never been. Time to collect the pay in %townname%.}",
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
				local q = ::ChaosMind.Quest;
				local def = this.Contract.getDef();
				local sword = ::ChaosMind.findSword();
				this.List.push({
					id = 10,
					icon = "ui/icons/fatigue.png",
					text = "Chaos Mind now grants +" + def.Rate + " max fatigue per +1% damage from kills" + (sword != null ? " (now +" + q.getStaminaBonus(sword) + ")" : "")
				});
			}
		});
		this.m.Screens.push({
			ID = "Failure",
			Title = "After the battle...",
			Text = "[img]gfx/ui/events/event_143.png[/img]{The %party% are gone, but their master did not die on the blade. The eye in the crossguard stays shut, and %employer% will not pay for half a job.\n\nSomewhere a new black skull is being painted.}",
			Image = "",
			List = [],
			Options = [
				{
					Text = "Next time, the blade.",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractFail);
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractFail, "Failed to break the black skull");
						this.World.Contracts.finishActiveContract(true);
						return 0;
					}
				}
			],
			function start()
			{
				this.List.push({
					id = 10,
					icon = "ui/icons/kills.png",
					text = "This part of the hunt will be offered again from tomorrow"
				});
			}
		});
		this.m.Screens.push({
			ID = "Success",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_04.png[/img]{%employer% counts the crowns out himself, and doesn't look at the blade while he does.%SPEECH_ON%The roads are quiet again. Whatever that thing you carry is, it did its work.%SPEECH_OFF%}",
			Image = "",
			Characters = [],
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "The skull is broken.",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Broke the black skull");
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

	// Accepting: the marked party, spawned the same way as the Black Skull always was.
	function spawnTarget()
	{
		local q = ::ChaosMind.Quest;
		q.Town = this.World.getEntityByID(this.m.Home.getID());
		q.PartyName = this.getDef().Name;
		local party = null;

		try
		{
			party = q.spawnTarget();
		}
		catch (e)
		{
			::logError("Chaos Mind: the Black Skull contract could not spawn its party (" + e + ").");
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
		local party = ::ChaosMind.Quest.getTarget();
		this.m.Target = party != null ? this.WeakTableRef(party) : null;
		this.m.Flags.set("Spawned", true);
	}

	function onPrepareVariables( _vars )
	{
		local target = (this.m.Target != null && !this.m.Target.isNull()) ? this.m.Target : null;
		_vars.push([
			"party",
			this.getDef().Name
		]);
		_vars.push([
			"where",
			target != null ? ::ChaosMind.Altar.describeLocation(target.getTile()) : "nearby"
		]);
	}

	function onClear()
	{
		if (this.m.IsActive && this.m.Home != null && !this.m.Home.isNull())
		{
			this.m.Home.getSprite("selection").Visible = false;
		}
	}

	// Still worth offering: none running and the next part open. Always true once accepted.
	function onIsValid()
	{
		if (this.m.IsActive || this.m.IsRestoring)
		{
			return true;
		}

		local q = ::ChaosMind.Quest;
		return q.getActive() == 0 && q.isNextPartOpen();
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
