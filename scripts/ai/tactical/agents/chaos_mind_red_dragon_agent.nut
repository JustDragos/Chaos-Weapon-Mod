// The Red Dragon's body: one behavior runs its whole turn (ai_chaos_mind_dragon).
this.chaos_mind_red_dragon_agent <- this.inherit("scripts/ai/tactical/agent", {
	m = {},
	function create()
	{
		this.agent.create();
		this.m.ID = this.Const.AI.Agent.ID.ChaosMindRedDragon;
		this.m.Properties.OverallDefensivenessMult = 0.0;
		this.m.Properties.OverallFormationMult = 0.0;
		this.m.Properties.PreferCarefulEngage = false;
	}

	function onAddBehaviors()
	{
		this.addBehavior(this.new("scripts/ai/tactical/behaviors/ai_chaos_mind_dragon"));
	}
});
