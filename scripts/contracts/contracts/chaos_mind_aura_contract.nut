// Aura of 10 as a real contract (::ChaosMind.Contracts): offered by the town the company is in once
// the blade has 250 kills, negotiated like any other. Accepting spawns The Ten
// (::ChaosMind.Aura.spawnTarget). Once they are all dead the amulet goes to the stash, and the
// company returns to the town to be paid. It can't fail.
// Built on the readable Legends contract legend_hunting_mummies_contract.
this.chaos_mind_aura_contract <- this.inherit("scripts/contracts/contract", {
	m = {
		Target = null,
		// Set while ::ChaosMind.Contracts rebuilds an accepted contract after loading.
		IsRestoring = false
	},
	function create()
	{
		this.contract.create();
		this.m.Type = "contract.chaos_mind_aura";
		this.m.Name = "Aura of 10";
		this.m.TimeOut = this.Time.getVirtualTimeF() + this.World.getTime().SecondsPerDay * 7.0;

		if ("DescriptionTemplates" in this.m)
		{
			this.m.DescriptionTemplates = [
				"Ten champions ride together, and the town would sleep easier with them dead."
			];
		}
	}

	function onImportIntro()
	{
		this.importSettlementIntro();
	}

	function start()
	{
		local a = ::ChaosMind.Aura;
		this.m.DifficultyMult = a.ContractDifficultyMult;
		this.m.Payment.Pool = a.ContractPay * this.getPaymentMult() * this.Math.pow(this.getDifficultyMult(), this.Const.World.Assets.ContractRewardPOW) * this.getReputationToPaymentMult();
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
					"Kill all of The Ten, ten champions around " + this.Contract.m.Home.getName()
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
					"Kill all of The Ten, ten champions around " + this.Contract.m.Home.getName()
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

				if (!this.Flags.has("Spawned"))
				{
					::logWarning("Chaos Mind: the Aura of 10 contract had no party to hunt; it is dropped.");
					::ChaosMind.Aura.decline();
					this.World.Contracts.finishActiveContract(true);
					return;
				}

				local a = ::ChaosMind.Aura;
				this.World.Flags.set(a.StateFlag, 2);
				this.World.Flags.set(a.TargetFlag, 0);
				this.World.Flags.set(a.OwedFlag, true);
				a.giveOwed();
				::logInfo("Chaos Mind: The Ten are gone; the Aura of 10 contract is done.");
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
			Text = "[img]gfx/ui/events/event_143.png[/img]{%employer% doesn't sit down.%SPEECH_ON%Ten riders. Champions, every one of them, sworn to ride together until one of them holds a blade worth the oath. They've been seen around %townname%, and they've heard of yours.%SPEECH_OFF%He looks at Chaos Mind for a long moment.%SPEECH_ON%They wear a medallion between them, gold. Whoever holds it never walks alone, they say. Kill all ten and keep it, for all I care. I'll add %reward% crowns so they never ride through here again.%SPEECH_OFF%}",
			Image = "",
			List = [],
			ShowEmployer = true,
			ShowDifficulty = true,
			Options = [
				{
					Text = "{Ten champions. Let's talk pay. | The %companyname% can do this, for the right price.}",
					function getResult()
					{
						return "Negotiation";
					}
				},
				{
					Text = "{Not now. | Ten champions is too much for us right now.}",
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
					text = "Ten named human champions, all in one party"
				});
				this.List.push({
					id = 11,
					icon = "ui/items/accessory/aura_of_10.png",
					text = "Also: Aura of 10, an amulet that makes the company count as ten seasoned men on the map"
				});
			}
		});
		this.m.Screens.push({
			ID = "Victory",
			Title = "After the battle...",
			Text = "[img]gfx/ui/events/event_140.png[/img]{The last of The Ten falls, and the field goes quiet. Around the neck of the first of them hangs a gold medallion, warm as a living thing.\n\nWhen the wielder lifts it, the air behind him fills with pale shapes. Ten of them, shields up, and they do not go away. Time to collect the pay in %townname%.}",
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
				local owed = this.World.Flags.has(::ChaosMind.Aura.OwedFlag) && this.World.Flags.get(::ChaosMind.Aura.OwedFlag);
				this.List.push({
					id = 10,
					icon = "ui/items/accessory/aura_of_10.png",
					text = owed ? "Aura of 10 waits until the stash has a free slot" : "You gain Aura of 10"
				});
			}
		});
		this.m.Screens.push({
			ID = "Success",
			Title = "On your return...",
			Text = "[img]gfx/ui/events/event_04.png[/img]{%employer% hears you out and pays without haggling.%SPEECH_ON%Ten champions. I'd have said it couldn't be done.%SPEECH_OFF%His eyes keep drifting to the space behind the wielder, as if he could almost see something standing there.}",
			Image = "",
			Characters = [],
			List = [],
			ShowEmployer = true,
			Options = [
				{
					Text = "Never alone.",
					function getResult()
					{
						this.World.Assets.addBusinessReputation(this.Const.World.Assets.ReputationOnContractSuccess);
						this.World.Assets.addMoney(this.Contract.m.Payment.getOnCompletion());
						this.World.FactionManager.getFaction(this.Contract.getFaction()).addPlayerRelation(this.Const.World.Assets.RelationCivilianContractSuccess, "Killed The Ten");
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

	// Accepting: The Ten, spawned the same way as the Aura of 10 hunt always was.
	function spawnTarget()
	{
		local a = ::ChaosMind.Aura;
		a.Town = this.World.getEntityByID(this.m.Home.getID());
		local party = null;

		try
		{
			party = a.spawnTarget();
		}
		catch (e)
		{
			::logError("Chaos Mind: the Aura of 10 contract could not spawn The Ten (" + e + ").");
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
		local party = ::ChaosMind.Aura.getTarget();
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

		return ::ChaosMind.Aura.isOpen();
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
