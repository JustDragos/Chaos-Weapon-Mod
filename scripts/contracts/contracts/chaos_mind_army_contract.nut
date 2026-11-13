// Army of the Past as a real contract (::ChaosMind.Contracts, ::ChaosMind.Army): offered by the town
// the company is in once the next part is open, negotiated like any other. Accepting spawns the host
// in groups of 50 plain skeletons. Once every group is gone the part is done, and the company
// returns to the town to be paid. It can't fail.
// Built on the readable Legends contract legend_hunting_mummies_contract.
this.chaos_mind_army_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Targets = [],
		// Set while ::ChaosMind.Contracts rebuilds an accepted contract after loading.
		IsRestoring = false
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.chaos_mind_army";
		this.m.Name = "Army of the Past";
		this.m.Targets = [];
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 7.0;

		if ("DescriptionTemplates" in this.m)
		{
			this.m.DescriptionTemplates = [
				"The dead of an old war are marching again near the town. Hundreds of them."
			];
		}
	}

	function getTier()
	{
		return this.m.Flags.has("Tier") ? this.m.Flags.get("Tier") : ::ChaosMind.Army.getDone() + 1;
	}

	function getDef()
	{
		local a = ::ChaosMind.Army;
		return a.Tiers[::Math.min(a.Tiers.len(), this.getTier()) - 1];
	}

	function getObjective()
	{
		local def = this.getDef();
		return "Destroy the Army of the Past around " + this.m.Home.getName() + ": " + def.Count + " skeletons in " + (def.Count / ::ChaosMind.Army.GroupSize) + " groups";
	}

	function getAliveTargets()
	{
		local alive = [];

		foreach (t in this.m.Targets)
		{
			if (t != null && !t.isNull() && t.isAlive())
			{
				alive.push(t);
			}
		}

		return alive;
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
				this.Contract.m.BulletpointsObjectives = [ this.Contract.getObjective() ];
				this.Contract.setScreen("Task");
			}

			function end()
			{
				if (this.Contract.m.IsRestoring)
				{
					return;
				}

				this.World.Assets.addMoney(this.Contract.m.Payment.getInAdvance());
				this.Flags.set("Tier", ::ChaosMind.Army.getDone() + 1);
				this.Contract.spawnTargets();
				this.Contract.setScreen("Overview");
				this.World.Contracts.setActiveContract(this.Contract);
			}
		});
		this.m.States.push({
			ID = "Running",
			function start()
			{
				this.Contract.m.BulletpointsObjectives = [ this.Contract.getObjective() ];

				foreach (t in this.Contract.getAliveTargets())
				{
					::ChaosMind.markTarget(t);
				}
			}

			function update()
			{
				if (this.Contract.getAliveTargets().len() != 0)
				{
					return;
				}

				local a = ::ChaosMind.Army;

				if (!this.Flags.has("Spawned"))
				{
					::logWarning("Chaos Mind: the Army of the Past contract had no host to fight; it is dropped.");
					a.decline();
					this.World.Contracts.finishActiveContract(true);
					return;
				}

				local tier = this.Contract.getTier();
				a.clearHunt();
				this.World.Flags.set(a.DoneFlag, tier);
				::logInfo("Chaos Mind: the Army of the Past (part " + tier + ") is destroyed by contract.");
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
			Text = "[img]gfx/ui/events/event_29.png[/img]{%employer% speaks quietly, as if the dead could hear him.%SPEECH_ON%The old battlefield past %townname% won't stay buried. Skeletons, hundreds of them, in the rusted gear of a war nobody remembers. Each one is no great threat. All of them together are the end of this town.%SPEECH_OFF%He pushes a purse across the table.%SPEECH_ON%Break them, every last group, and %reward% crowns are yours.%SPEECH_OFF%The eye in Chaos Mind's crossguard opens. The dead have no souls left, but the blade will take what it can.}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{The dead are easy prey. Let's talk pay. | The %companyname% can do this, for the right price.}",
					function getResult()
					{
						return "Negotiation";
					}
				},
				{
					Text = "{Not now. | That's too many even for us.}",
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
					icon = "ui/icons/kills.png",
					text = "Part " + this.Contract.getTier() + " of " + ::ChaosMind.Army.Tiers.len() + ": " + def.Count + " plain skeletons, in groups of " + ::ChaosMind.Army.GroupSize + " (one battle each)"
				});
				this.List.push({
					id = 11,
					icon = "ui/icons/special.png",
					text = "Every skeleton the blade kills counts towards its kills"
				});
			}
		});
		this.m.Screens.push({
			ID = "Victory",
			Title = "After the battle...",
			Text = "[img]gfx/ui/events/event_46.png[/img]{The last of the dead falls apart, and this time the bones stay where they lie. The field is quiet. The blade hums, fed on whatever the old soldiers still had in them.\n\nTime to collect the pay in %townname%.}",
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
			]
		});
		this.m.Screens.push({
			ID = "Success",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_04.png[/img]{%employer% has heard already. The whole town has.%SPEECH_ON%They say the old battlefield is just bones again. Here, as promised.%SPEECH_OFF%}",
			Image = "",
			Characters = [],
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "Back into the ground with them.",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Destroyed the Army of the Past");
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

	// Accepting: the host, in groups (::ChaosMind.Army.spawnTargets).
	function spawnTargets()
	{
		local a = ::ChaosMind.Army;
		a.Town = this.World.getEntityByID(this.m.Home.getID());
		local groups = [];

		try
		{
			groups = a.spawnTargets();
		}
		catch (e)
		{
			::logError("Chaos Mind: the Army of the Past contract could not spawn its host (" + e + ").");
		}

		this.m.Targets = [];

		foreach (g in groups)
		{
			this.m.Targets.push(this.WeakTableRef(g));
		}

		if (groups.len() != 0)
		{
			this.m.Flags.set("Spawned", true);
		}
	}

	// After loading: the groups still standing.
	function relinkTarget()
	{
		this.m.Targets = [];

		foreach (g in ::ChaosMind.Army.getTargets())
		{
			this.m.Targets.push(this.WeakTableRef(g));
		}

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

		return ::ChaosMind.Army.isOpen();
	}

	function onSerialize( _out )
	{
		local alive = this.getAliveTargets();
		_out.writeU8(alive.len());

		foreach (t in alive)
		{
			_out.writeU32(t.getID());
		}

		this.contract.onSerialize(_out);
	}

	function onDeserialize( _in )
	{
		this.m.Targets = [];
		local count = _in.readU8();

		for (local i = 0; i < count; ++i)
		{
			local party = this.World.getEntityByID(_in.readU32());

			if (party != null)
			{
				this.m.Targets.push(this.WeakTableRef(party));
			}
		}

		this.contract.onDeserialize(_in);
	}
});
