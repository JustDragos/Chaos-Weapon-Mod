// Given to every brother who sees a comrade sacrificed (see ::ChaosMind.OnlyChaos.terrifyAllies).
// He flees and cannot rally until the battle ends: Fleeing is forced again at the start and end
// of each of his turns and every new round, and Rally the Troops is undone for him
// (only_chaos_matters.nut).
this.sacrifice_terror_effect <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "effects.sacrifice_terror";
		this.m.Name = "Terrified by the Sacrifice";
		this.m.Icon = "skills/chaos_mind/mass_sacrifice.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function getDescription()
	{
		return "This character watched a brother cut down by his own for the blade. He runs, and nothing will make him stand and fight again in this battle.";
	}

	function getTooltip()
	{
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
				icon = "ui/tooltips/warning.png",
				text = "Flees and cannot rally until the battle ends"
			}
		];
	}

	function forceFleeing()
	{
		local actor = this.getContainer().getActor();

		if (actor.isAlive() && actor.getMoraleState() != this.Const.MoraleState.Fleeing)
		{
			actor.setMoraleState(this.Const.MoraleState.Fleeing);
		}
	}

	function onAdded()
	{
		this.forceFleeing();
	}

	// Any natural rally is undone at every point of the turn cycle.
	function onTurnStart()
	{
		this.forceFleeing();
	}

	function onTurnEnd()
	{
		this.forceFleeing();
	}

	function onNewRound()
	{
		this.forceFleeing();
	}
});
