// Given to anyone standing in a Chaos Circle (see ::ChaosMind.ChaosCircle): moving costs
// +1 AP and +3 fatigue per tile. Taken away as soon as he leaves it or it fades.
//
// Uses the character properties MovementAPCostAdditional / MovementFatigueCostAdditional, so the
// game's own path costs include it. Their names couldn't be confirmed in the encrypted scripts:
// if they're missing, the cost is charged per step instead (onMovementStep, from MSU).
this.chaos_circle_effect <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "effects.chaos_circle";
		this.m.Name = "Caught in a Chaos Circle";
		this.m.Icon = "skills/chaos_mind/chaos_circle.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function getDescription()
	{
		return "Grasping hands rise from the torn ground. Every step out of here is dragged and fought for.";
	}

	function getTooltip()
	{
		local cc = ::ChaosMind.ChaosCircle;

		return [
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
				id = 10,
				type = "text",
				icon = "ui/icons/action_points.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]+" + cc.MoveAPCost + "[/color] Action Point per tile moved"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/fatigue.png",
				text = "[color=" + this.Const.UI.Color.NegativeValue + "]+" + cc.MoveFatigueCost + "[/color] Fatigue per tile moved"
			}
		];
	}

	function onUpdate( _properties )
	{
		local cc = ::ChaosMind.ChaosCircle;
		local found = ("MovementAPCostAdditional" in _properties) && ("MovementFatigueCostAdditional" in _properties);

		if (cc.HasMovementProperties == null)
		{
			cc.HasMovementProperties = found;
			::logInfo("Chaos Mind: Chaos Circle slow uses " + (found ? "movement cost properties" : "per-step charging (movement cost properties not found)") + ".");
		}

		if (found)
		{
			_properties.MovementAPCostAdditional += cc.MoveAPCost;
			_properties.MovementFatigueCostAdditional += cc.MoveFatigueCost;
		}
	}

	function onMovementStep( _tile, _levelDifference )
	{
		local cc = ::ChaosMind.ChaosCircle;

		if (cc.HasMovementProperties != false)
		{
			return;
		}

		local actor = this.getContainer().getActor();
		actor.setActionPoints(::Math.max(0, actor.getActionPoints() - cc.MoveAPCost));
		actor.setFatigue(::Math.min(actor.getFatigueMax(), actor.getFatigue() + cc.MoveFatigueCost));
	}

	function onNewRound()
	{
		::ChaosMind.ChaosCircle.updateActor(this.getContainer().getActor());
	}

	function onTurnStart()
	{
		::ChaosMind.ChaosCircle.updateActor(this.getContainer().getActor());
	}
});
