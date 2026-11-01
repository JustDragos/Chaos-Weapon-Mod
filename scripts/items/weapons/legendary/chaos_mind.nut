this.chaos_mind <- this.inherit("scripts/items/weapons/greatsword", {
	m = {
		KillsPerBonus = 10,
		DevourerKills = 100,
		AscendedKills = 500,
		KillsPerChampionBonus = 20,
		ChampionBonusStep = 2,
		ChampionBonusMax = 35,
		Kills = 0
	},
	function create()
	{
		this.greatsword.create();
		this.m.ID = ::ChaosMind.SwordID;
		this.m.Description = "A blade forged in a fever. The storm it releases knows no allegiance.";
		// Icons and the in-battle sprite (brushes/chaos_mind.brush, each with an "_bloodied"
		// variant) are set by updateName(), and change at 500 kills.
		this.m.Value = 40000;
		this.m.RegularDamage = 100;
		this.m.RegularDamageMax = 120;
		this.updateName();

		// Diagnostics: log who creates every copy (the altar, a save being loaded, or anything
		// else), so an unexpected duplicate shows its source in log.html.
		local caller = ::getstackinfos(2);
		::logInfo("Chaos Mind: sword object created by " + (caller != null ? caller.src + " : " + caller.func + " line " + caller.line : "unknown"));

		if ("Legendary" in this.Const.Items.ItemType)
		{
			this.m.ItemType = this.m.ItemType | this.Const.Items.ItemType.Legendary;
		}
	}

	// Damage multiplier from the wielder's Melee Skill: +0.5% per point, or the full +1% per
	// point once he has the Chaos Armor perk. Used by attacks and by Brother / Mass Sacrifice.
	function getMeleeSkillMult( _actor, _meleeSkill )
	{
		local perPoint = _actor.getSkills().hasSkill("perk.chaos_armor") ? 1.0 : 0.5;
		return 1.0 + _meleeSkill * perPoint / 100.0;
	}

	// Permanent +1% damage for every KillsPerBonus kills, brothers included (applied in chaos_mind_effect).
	function getKillBonus()
	{
		return this.m.Kills / this.m.KillsPerBonus;
	}

	// Extra chance (in %) for each enemy to become a champion in battles the wielder fights in
	// (applied in chaos_mind_effect): +2% per 20 kills, at most 35%.
	function getChampionBonus()
	{
		return ::Math.min(this.m.ChampionBonusMax, (this.m.Kills / this.m.KillsPerChampionBonus) * this.m.ChampionBonusStep);
	}

	function isDevourer()
	{
		return this.m.Kills >= this.m.DevourerKills;
	}

	// At 500 kills the blade takes its gorged form: new icons and battle sprite.
	function isAscended()
	{
		return this.m.Kills >= this.m.AscendedKills;
	}

	// Name, icons and battle sprite for the current kill count.
	function updateName()
	{
		this.m.Name = this.isDevourer() ? "Chaos Mind, the Devourer" : "Chaos Mind";

		local suffix = this.isAscended() ? "_500" : "";
		this.m.IconLarge = "weapons/legendary/chaos_mind" + suffix + ".png";
		this.m.Icon = "weapons/legendary/chaos_mind" + suffix + "_70x70.png";

		local armament = this.isAscended() ? "icon_chaos_mind_500" : "icon_chaos_mind_01";

		if (this.m.ArmamentIcon != armament)
		{
			this.m.ArmamentIcon = armament;

			// Refresh the sprite in the wielder's hands if it changes mid-battle.
			try
			{
				this.updateAppearance();
			}
			catch (e)
			{
			}
		}
	}

	// Returns "ascended" at 500 kills, "devourer" at 100, "bonus" when the damage bonus rose, else null.
	function addKill()
	{
		local before = this.getKillBonus();
		local wasDevourer = this.isDevourer();
		local wasAscended = this.isAscended();
		this.m.Kills += 1;
		this.updateName();

		if (!wasAscended && this.isAscended())
		{
			return "ascended";
		}

		if (!wasDevourer && this.isDevourer())
		{
			return "devourer";
		}

		return this.getKillBonus() > before ? "bonus" : null;
	}

	function onSerialize( _out )
	{
		this.greatsword.onSerialize(_out);
		_out.writeU32(this.m.Kills);
	}

	function onDeserialize( _in )
	{
		this.greatsword.onDeserialize(_in);

		// The kill count follows the weapon data in saves made with this mod, and in older saves
		// from when Chaos Mind lived in Blacksmith's Workshop (1.1.0+). Earlier saves have none.
		local meta = _in.getMetaData();
		local hasKills = ::ChaosMind.Mod.Serialization.isSavedVersionAtLeast("1.0.0", meta);

		if (!hasKills)
		{
			local blacksmith = meta.getString("mod_blacksmith_workshopVersion");
			hasKills = blacksmith != "" && ::MSU.SemVer.compareVersionWithOperator(blacksmith, ">=", "1.1.0");
		}

		if (hasKills)
		{
			this.m.Kills = _in.readU32();
		}

		this.updateName();
	}

	function getTooltip()
	{
		local result = this.greatsword.getTooltip();
		local nextForm = !this.isDevourer() ? " Awakens at " + this.m.DevourerKills + "." : (!this.isAscended() ? " Changes form at " + this.m.AscendedKills + "." : "");

		// Kept short: the Chaos Guide explains everything the blade does.
		result.push({
			id = 20,
			type = "text",
			icon = "ui/icons/kills.png",
			text = this.m.Kills + " slain: [color=" + this.Const.UI.Color.PositiveValue + "]+" + this.getKillBonus() + "%[/color] damage." + nextForm
		});
		result.push({
			id = 21,
			type = "text",
			icon = "ui/tooltips/warning.png",
			text = "[color=" + this.Const.UI.Color.NegativeValue + "]Cursed:[/color] its hits also wound everyone near the target and the wielder's nearby allies"
		});
		local stamina = ::ChaosMind.Quest.getStaminaBonus(this);

		if (stamina > 0)
		{
			result.push({
				id = 23,
				type = "text",
				icon = "ui/icons/fatigue.png",
				text = "Black Skull: [color=" + this.Const.UI.Color.PositiveValue + "]+" + stamina + "[/color] max fatigue for the wielder"
			});
		}

		result.push({
			id = 22,
			type = "text",
			icon = "ui/icons/special.png",
			text = "Read the Chaos Guide ([color=" + this.Const.UI.Color.PositiveValue + "]" + ::ChaosMind.getGuideKey() + "[/color]) for everything it does"
		});

		return result;
	}

	function onEquip()
	{
		this.greatsword.onEquip();
		this.addSkill(this.new("scripts/skills/effects/chaos_mind_effect"));
		this.addSkill(this.new("scripts/skills/actives/carnal_storage_skill"));
		this.addSkill(this.new("scripts/skills/actives/brother_sacrifice_skill"));
		this.addSkill(this.new("scripts/skills/actives/mass_sacrifice_skill"));
	}

});
