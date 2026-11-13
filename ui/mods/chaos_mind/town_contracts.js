"use strict";

// This mod's contracts get their own purple banner in the town's contract row instead of the
// faction's. The town screen draws each contract from _data.Contracts[i].Icon (+ '.png', 'b.png'
// on hover, 'w.png' while another contract is active); for this mod's contracts that path is
// swapped before the game draws them. Which contracts are this mod's, and their banners, come from
// scripts/mods/chaos_mind/contract_icon_screen.nut (::ChaosMind.Contracts.sendIcons).
var ChaosMindContractIcons = function ()
{
	MSUUIScreen.call(this);
	this.mID = "ChaosMindContractIcons";
	this.mIcons = {};
};

ChaosMindContractIcons.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(ChaosMindContractIcons.prototype, 'constructor', {
	value: ChaosMindContractIcons,
	enumerable: false,
	writable: true
});

ChaosMindContractIcons.prototype.createDIV = function (_parentDiv)
{
	this.mContainer = $('<div class="display-none"/>');
	_parentDiv.append(this.mContainer);
};

ChaosMindContractIcons.prototype.setIcons = function (_icons)
{
	ChaosMindInstallContractIconHook();
	var icons = {};

	if (_icons !== null && _icons !== undefined)
	{
		_icons.forEach(function (_entry)
		{
			icons[_entry.ID] = _entry.Icon;
		});
	}

	this.mIcons = icons;
};

// The banner for a contract, or null if it isn't this mod's.
ChaosMindContractIcons.prototype.getIcon = function (_id)
{
	return (_id in this.mIcons) ? this.mIcons[_id] : null;
};

var ChaosMindContractIconsScreen = new ChaosMindContractIcons();
registerScreen("ChaosMindContractIcons", ChaosMindContractIconsScreen);

// Installed at load, and again with every update in case the town screen's script loads later.
var ChaosMindContractIconHookInstalled = false;

function ChaosMindInstallContractIconHook()
{
	if (ChaosMindContractIconHookInstalled || typeof WorldTownScreenMainDialogModule === 'undefined')
	{
		return;
	}

	ChaosMindContractIconHookInstalled = true;
	var updateContracts = WorldTownScreenMainDialogModule.prototype.updateContracts;

	WorldTownScreenMainDialogModule.prototype.updateContracts = function (_data)
	{
		if (_data !== null && _data !== undefined && 'Contracts' in _data && _data.Contracts !== null)
		{
			for (var i = 0; i < _data.Contracts.length; ++i)
			{
				var c = _data.Contracts[i];
				var icon = c !== null ? ChaosMindContractIconsScreen.getIcon(c.ID) : null;

				if (icon !== null)
				{
					c.Icon = icon;
				}
			}
		}

		updateContracts.call(this, _data);
	};
}

ChaosMindInstallContractIconHook();
