// Hidden, and held only for the instant a Chaos Circle screams at someone
// (::ChaosMind.ChaosCircle.scream): lowers his Resolve by -Shift, set before it's added.
// Divided by his BraveryMult (if he has one) so the Resolve he checks with moves by the full Shift.
this.chaos_circle_ward_effect <- this.inherit("scripts/skills/skill", {
	m = {
		Shift = 0
	},
	function create()
	{
		this.m.ID = "effects.chaos_circle_ward";
		this.m.Name = "Chaos Circle Ward";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsHidden = true;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	function onUpdate( _properties )
	{
		if ("Bravery" in _properties)
		{
			local mult = ("BraveryMult" in _properties && _properties.BraveryMult > 0) ? _properties.BraveryMult : 1.0;
			_properties.Bravery += this.m.Shift / mult;
		}
	}
});
