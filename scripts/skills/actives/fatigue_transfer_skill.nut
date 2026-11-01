// Granted by the Fatigue Transfer perk. 1 AP: all of the user's fatigue moves onto an adjacent
// enemy (up to that enemy's maximum) and the user drops to 0. 3-turn cooldown.
this.fatigue_transfer_skill <- this.inherit("scripts/skills/skill", {
	m = {
		Cooldown = 3,
		TurnsLeft = 0
	},
	function create()
	{
		this.m.ID = "actives.fatigue_transfer";
		this.m.Name = "Fatigue Transfer";
		this.m.Description = "Lay a hand on a foe and push every ounce of your exhaustion into him. You stand fresh; he staggers under the weight.";
		this.m.Icon = "skills/chaos_mind/fatigue_transfer.png";
		this.m.IconDisabled = "skills/chaos_mind/fatigue_transfer_sw.png";
		this.m.Overlay = "active_118";
		this.m.SoundOnUse = [];
		this.m.Type = this.Const.SkillType.Active;
		this.m.Order = ("Any" in this.Const.SkillOrder) ? this.Const.SkillOrder.Any : this.Const.SkillOrder.Last;
		this.m.IsSerialized = false;
		this.m.IsActive = true;
		this.m.IsTargeted = true;
		this.m.IsStacking = false;
		this.m.IsAttack = false;
		this.m.ActionPointCost = 1;
		this.m.FatigueCost = 0;
		this.m.MinRange = 1;
		this.m.MaxRange = 1;
	}

	function getTooltip()
	{
		local actor = this.getContainer().getActor();
		local ret = [
			{
				id = 1,
				type = "title",
				text = this.getName()
			},
			{
				id = 2,
				type = "description",
				text = this.getDescription()
			},
			{
				id = 3,
				type = "text",
				text = this.getCostString()
			},
			{
				id = 10,
				type = "text",
				icon = "ui/icons/fatigue.png",
				text = "Moves all your fatigue ([color=" + this.Const.UI.Color.NegativeValue + "]" + actor.getFatigue().tointeger() + "[/color]) onto an adjacent enemy, up to his maximum. Yours drops to [color=" + this.Const.UI.Color.PositiveValue + "]0[/color]"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/special.png",
				text = "Can be used once every " + this.m.Cooldown + " turns"
			}
		];

		if (this.m.TurnsLeft > 0)
		{
			ret.push({
				id = 12,
				type = "text",
				icon = "ui/tooltips/warning.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]Ready again in " + this.m.TurnsLeft + (this.m.TurnsLeft == 1 ? " turn" : " turns") + "[/color]"
			});
		}

		return ret;
	}

	function isUsable()
	{
		return this.skill.isUsable() && this.m.TurnsLeft == 0 && this.getContainer().getActor().getFatigue() > 0;
	}

	function onVerifyTarget( _originTile, _targetTile )
	{
		if (!_targetTile.IsOccupiedByActor)
		{
			return false;
		}

		local target = _targetTile.getEntity();
		return target != null && target.isAlive() && !target.isAlliedWith(this.getContainer().getActor());
	}

	function onUse( _user, _targetTile )
	{
		local target = _targetTile.getEntity();

		if (target == null)
		{
			return false;
		}

		local amount = _user.getFatigue();
		local before = target.getFatigue();
		local after = ::Math.min(target.getFatigueMax(), before + amount);

		target.setFatigue(after);
		_user.setFatigue(0);
		target.setDirty(true);
		_user.setDirty(true);

		this.m.TurnsLeft = this.m.Cooldown;

		local text = "transfers " + amount.tointeger() + " fatigue to " + target.getName() + " (" + before.tointeger() + " -> " + after.tointeger() + "/" + target.getFatigueMax().tointeger() + ")";
		::logInfo("Chaos Mind: " + _user.getName() + " " + text);

		try
		{
			::Tactical.EventLog.log(::Const.UI.getColorizedEntityName(_user) + " " + text);
		}
		catch (e)
		{
		}

		return true;
	}

	function onTurnStart()
	{
		if (this.m.TurnsLeft > 0)
		{
			this.m.TurnsLeft -= 1;
		}
	}

	function onCombatStarted()
	{
		this.m.TurnsLeft = 0;
	}

	function onCombatFinished()
	{
		this.m.TurnsLeft = 0;
	}
});
