// Legendary location in the arctic where Chaos Mind waits, buried in the ice.
this.chaos_mind_altar_location <- this.inherit("scripts/entity/world/location", {
	m = {},

	function getDescription()
	{
		return "A greatsword stands buried in the frozen ground. The snow around it is stained violet, and something in its hilt is watching.";
	}

	function create()
	{
		this.location.create();

		this.m.Name = "The Frozen Eye";
		this.m.TypeID = "location.chaos_mind_altar";
		this.m.LocationType = this.Const.World.LocationType.Unique;

		this.m.IsShowingDefenders = false;
		this.m.IsShowingBanner = false;
		this.m.IsAttackable = false;
		this.m.IsDespawningDefenders = false;

		this.m.VisibilityMult = 1.0;
		this.m.Resources = 0;

		this.m.OnEnter = "event.location.chaos_mind_altar";
	}

	function onInit()
	{
		this.location.onInit();

		// Custom sprite from brushes/chaos_mind_world.brush.
		local body = this.addSprite("body");
		body.setBrush("world_chaos_mind_altar");
	}

	function onEnter()
	{
		::World.Events.fire("event.location.chaos_mind_altar");
		return false;
	}

	function onDeserialize( _in )
	{
		this.location.onDeserialize(_in);

		local body = this.getSprite("body");

		if (body != null)
		{
			body.setBrush("world_chaos_mind_altar");
		}

		this.m.OnEnter = "event.location.chaos_mind_altar";
		this.m.IsAttackable = false;
	}
});
