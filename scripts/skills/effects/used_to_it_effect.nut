// Shows the Used to It stacks in battle. The bonus itself is applied by perk_used_to_it.
this.used_to_it_effect <- this.inherit("scripts/skills/skill", {
	m = {},
	function create()
	{
		this.m.ID = "effects.used_to_it";
		this.m.Name = "Used to It";
		this.m.Icon = "skills/chaos_mind/used_to_it.png";
		this.m.IconMini = "";
		this.m.Type = this.Const.SkillType.StatusEffect;
		this.m.IsActive = false;
		this.m.IsStacking = false;
		this.m.IsRemovedAfterBattle = true;
		this.m.IsSerialized = false;
	}

	// Also called by the game while removing the effect at the end of a battle (for its name),
	// when it no longer has a container: an error here stopped the battle from ending, so any
	// failure just counts as no bonus.
	function getBonus()
	{
		try
		{
			local container = this.getContainer();

			if (::MSU.isNull(container) || ::MSU.isNull(container.getActor()))
			{
				return 0;
			}

			local perk = ::ChaosMind.UsedToIt.getPerk(container.getActor());
			return perk == null ? 0 : perk.getStacks() * ::ChaosMind.UsedToIt.DefensePerStack;
		}
		catch (e)
		{
			return 0;
		}
	}

	function getName()
	{
		return this.m.Name + " (+" + this.getBonus() + ")";
	}

	function getDescription()
	{
		return "Every swing that misses only makes him calmer. He reads the next one a little earlier.";
	}

	function getTooltip()
	{
		local uti = ::ChaosMind.UsedToIt;
		local bonus = this.getBonus();

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
				icon = "ui/icons/melee_defense.png",
				text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + bonus + "[/color] Melee Defense"
			},
			{
				id = 11,
				type = "text",
				icon = "ui/icons/ranged_defense.png",
				text = "[color=" + this.Const.UI.Color.PositiveValue + "]+" + bonus + "[/color] Ranged Defense"
			},
			{
				id = 12,
				type = "text",
				icon = "ui/icons/special.png",
				text = "+" + uti.DefensePerStack + " more for each attack that misses him, up to +" + (uti.MaxStacks * uti.DefensePerStack) + ". Dodging costs him no fatigue"
			}
		];
	}
});
