// The Red Dragon in the air (chaos_mind/dragon.nut): its body stays on its hex but can't be seen,
// targeted or hurt until it lands on its next turn. Its parts are off the board meanwhile.
this.chaos_mind_dragon_airborne_effect <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "effects.chaos_mind_dragon_airborne";
		this.m.Name = "In the Air";
		this.m.Description = "The dragon circles high above the battlefield. It can't be seen or hurt until it lands.";
		this.m.Icon = "skills/status_effect_08.png";
		this.m.IconMini = "status_effect_08_mini";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsHidden = false;
		this.m.IsSerialized = false;
		this.m.IsRemovedAfterBattle = true;
	}

	function setVisible( _visible )
	{
		local actor = this.getContainer().getActor();

		try
		{
			actor.setHidden(!_visible);
		}
		catch (e)
		{
		}

		foreach (name in [ "body", "status_rooted", "status_stunned", "arrow" ])
		{
			try
			{
				actor.getSprite(name).Visible = _visible && name == "body";
			}
			catch (e)
			{
			}
		}

		try
		{
			actor.setDirty(true);
		}
		catch (e)
		{
		}
	}

	function onAdded()
	{
		this.setVisible(false);
	}

	function onRemoved()
	{
		this.setVisible(true);
	}

	function onUpdate( _properties )
	{
		_properties.TargetAttractionMult = 0.0;
		this.setVisible(false);
	}

	function onBeforeDamageReceived( _attacker, _skill, _hitInfo, _properties )
	{
		_properties.DamageReceivedTotalMult = 0.0;
	}
});
