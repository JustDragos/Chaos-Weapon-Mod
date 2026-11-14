// The Red Dragon's whole turn (chaos_mind/dragon.nut), once per turn:
//  - in the air: land (teleport the hidden body to the chosen spot, then the parts come back and
//    everyone next to it is pushed back);
//  - else, when it wants to fly: take off;
//  - else: roar every RoarEvery-th turn, then breathe fire if anyone is in front of its head.
// Then its action points go to 0 and the turn ends. Any error ends the turn instead of stalling it.
// Shaped like the readable Legends legend_ai_buff_howl (onEvaluate / onExecute).
this.ai_chaos_mind_dragon <- this.inherit("scripts/ai/tactical/behavior", {
	m = {
		Phase = 0,
		Landing = null,
		WaitUntil = 0.0
	},

	function create()
	{
		this.m.ID = this.Const.AI.Behavior.ID.ChaosMindDragon;
		this.m.Order = this.Const.AI.Behavior.Order.ChaosMindDragon;
		this.behavior.create();
	}

	function onEvaluate( _entity )
	{
		if (!_entity.getFlags().has("chaos_mind_red_dragon") || !("HasActed" in _entity.m) || _entity.m.HasActed)
		{
			return this.Const.AI.Behavior.Score.Zero;
		}

		return this.Const.AI.Behavior.Score.ChaosMindDragon;
	}

	function endTurn( _entity )
	{
		_entity.m.HasActed = true;
		this.m.Phase = 0;
		this.m.Landing = null;

		try
		{
			_entity.setActionPoints(0);
		}
		catch (e)
		{
			_entity.m.ActionPoints = 0;
		}

		return true;
	}

	function onExecute( _entity )
	{
		try
		{
			return this.act(_entity);
		}
		catch (e)
		{
			::logError("Chaos Mind: the Red Dragon's turn failed (" + e + "); it ends its turn.");
			return this.endTurn(_entity);
		}
	}

	function act( _entity )
	{
		local d = ::ChaosMind.Dragon;

		// Landing, step 2: wait for the hidden body to arrive, then show it.
		if (this.m.Phase == 1)
		{
			if (this.m.Landing.Arrived || ::Time.getRealTimeF() >= this.m.WaitUntil)
			{
				if (_entity.getTile().ID != this.m.Landing.Tile.ID)
				{
					::logWarning("Chaos Mind: the Red Dragon didn't reach its landing spot; it lands where it is.");
				}

				d.finishLanding(_entity, this.m.Landing);
				return this.endTurn(_entity);
			}

			return false;
		}

		if (_entity.isAirborne())
		{
			local choice = d.chooseLanding(_entity);

			if (choice == null)
			{
				::logInfo("Chaos Mind: the Red Dragon found nowhere to land; it stays in the air.");
				return this.endTurn(_entity);
			}

			choice.Arrived <- false;
			this.m.Landing = choice;

			if (choice.Tile.ID == _entity.getTile().ID)
			{
				d.finishLanding(_entity, choice);
				return this.endTurn(_entity);
			}

			this.m.Phase = 1;
			this.m.WaitUntil = ::Time.getRealTimeF() + 3.0;
			this.Tactical.getNavigator().teleport(_entity, choice.Tile, function( _e, _tag )
			{
				_tag.Arrived = true;
			}, choice, false, 1000.0);
			return false;
		}

		if (_entity.wantsToFly())
		{
			d.takeOff(_entity);
			return this.endTurn(_entity);
		}

		if (_entity.wantsToRoar())
		{
			d.roar(_entity);
		}

		if (d.countInCone(_entity) > 0)
		{
			d.breathe(_entity);
		}

		return this.endTurn(_entity);
	}
});
