// Army of the Past battles only (::ChaosMind.Army.onBattleSpawned), on every unit:
//  - a skeleton is frailer (hitpoints x Army.HitpointsMult) and its turns run at Army.FastSpeed;
//  - a brother's turns run at normal speed.
// Hidden, not saved, gone after the battle; the speed is put back to normal when it ends.
this.army_of_the_past_effect <- this.inherit("scripts/skills/skill", {
	m = {
		IsSkeleton = false
	},
	function create()
	{
		this.m.ID = "effects.army_of_the_past";
		this.m.Name = "Army of the Past";
		this.m.Icon = "skills/status_effect_14.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsHidden = true;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function onUpdate( _properties )
	{
		if (!this.m.IsSkeleton)
		{
			return;
		}

		local mult = ::ChaosMind.Army.HitpointsMult;

		if ("HitpointsMult" in _properties)
		{
			_properties.HitpointsMult *= mult;
		}
		else
		{
			_properties.Hitpoints = ::Math.max(1, ::Math.floor(_properties.Hitpoints * mult));
		}
	}

	function onTurnStart()
	{
		::ChaosMind.Army.setFast(this.m.IsSkeleton);
	}

	function onCombatFinished()
	{
		::ChaosMind.Army.setFast(false);
	}
});
