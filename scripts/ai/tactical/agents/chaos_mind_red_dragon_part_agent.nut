// A Red Dragon part: no behaviors. It has no action points on its turn, so the turn ends at once.
this.chaos_mind_red_dragon_part_agent <- this.inherit("scripts/ai/tactical/agent", {
	m = {},
	function create()
	{
		this.agent.create();
		this.m.ID = this.Const.AI.Agent.ID.ChaosMindRedDragonPart;
		this.m.Properties.OverallDefensivenessMult = 0.0;
		this.m.Properties.OverallFormationMult = 0.0;
	}

	function onAddBehaviors()
	{
	}
});
