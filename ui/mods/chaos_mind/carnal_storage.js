"use strict";

// Carnal Storage window: pick a sacrifice (Fatigue / Blood / Flesh), pick how much
// energy to take, and unleash stored energy. Backend: carnal_storage_screen.nut.
var CarnalStorageScreen = function ()
{
	MSUUIScreen.call(this);
	this.mID = "CarnalStorageScreen";
	this.mData = null;
	this.mMode = "Fatigue";
	this.mAmount = 1;

	this.mStatus = null;
	this.mModeButtons = {};
	this.mAmountRow = null;
	this.mAmountLabel = null;
	this.mCostLabel = null;
	this.mMinusButton = null;
	this.mPlusButton = null;
	this.mMaxButton = null;
	this.mSacrificeButton = null;
	this.mUnleashButton = null;
};

CarnalStorageScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(CarnalStorageScreen.prototype, 'constructor', {
	value: CarnalStorageScreen,
	enumerable: false,
	writable: true
});

CarnalStorageScreen.Modes = ["Fatigue", "Blood", "Flesh"];

CarnalStorageScreen.prototype.createDIV = function (_parentDiv)
{
	var self = this;

	this.mContainer = $('<div class="carnal-storage-screen display-none"/>');
	_parentDiv.append(this.mContainer);

	var dialog = $('<div class="carnal-storage-dialog"/>');
	this.mContainer.append(dialog);

	var header = $('<div class="carnal-storage-header"/>');
	dialog.append(header);
	header.append($('<img class="carnal-storage-eye" src="' + Path.GFX + 'skills/chaos_mind/carnal_storage.png"/>'));
	header.append($('<div class="carnal-storage-title title-font-very-big font-bold font-bottom-shadow font-color-title">Carnal Storage</div>'));

	this.mStatus = $('<div class="carnal-storage-status text-font-normal font-color-description"/>');
	dialog.append(this.mStatus);

	// What to sacrifice.
	dialog.append($('<div class="carnal-storage-label text-font-normal font-color-title">Sacrifice</div>'));
	var modeRow = $('<div class="carnal-storage-row"/>');
	dialog.append(modeRow);

	CarnalStorageScreen.Modes.forEach(function (_mode)
	{
		var layout = $('<div class="carnal-storage-mode-layout"/>');
		modeRow.append(layout);
		self.mModeButtons[_mode] = layout.createTextButton(_mode, function ()
		{
			self.selectMode(_mode);
		}, 'carnal-storage-button', 1);
	});

	// How much energy.
	this.mAmountRow = $('<div class="carnal-storage-row"/>');
	dialog.append(this.mAmountRow);

	var minusLayout = $('<div class="carnal-storage-small-layout"/>');
	this.mAmountRow.append(minusLayout);
	this.mMinusButton = minusLayout.createTextButton("-", function () { self.changeAmount(-1); }, 'carnal-storage-button', 1);

	this.mAmountLabel = $('<div class="carnal-storage-amount title-font-big font-bold font-color-title"/>');
	this.mAmountRow.append(this.mAmountLabel);

	var plusLayout = $('<div class="carnal-storage-small-layout"/>');
	this.mAmountRow.append(plusLayout);
	this.mPlusButton = plusLayout.createTextButton("+", function () { self.changeAmount(1); }, 'carnal-storage-button', 1);

	var maxLayout = $('<div class="carnal-storage-small-layout"/>');
	this.mAmountRow.append(maxLayout);
	this.mMaxButton = maxLayout.createTextButton("Max", function () { self.setAmount(self.getMaxEnergy()); }, 'carnal-storage-button', 1);

	this.mCostLabel = $('<div class="carnal-storage-cost text-font-normal font-color-description"/>');
	dialog.append(this.mCostLabel);

	// Actions.
	var actionRow = $('<div class="carnal-storage-row carnal-storage-actions"/>');
	dialog.append(actionRow);

	var sacrificeLayout = $('<div class="carnal-storage-action-layout"/>');
	actionRow.append(sacrificeLayout);
	this.mSacrificeButton = sacrificeLayout.createTextButton("Sacrifice", function ()
	{
		SQ.call(self.mSQHandle, 'onSacrificePressed', { Mode: self.mMode, Amount: self.mAmount });
	}, 'carnal-storage-button', 1);

	var unleashLayout = $('<div class="carnal-storage-action-layout"/>');
	actionRow.append(unleashLayout);
	this.mUnleashButton = unleashLayout.createTextButton("Unleash", function ()
	{
		SQ.call(self.mSQHandle, 'onUnleashPressed');
	}, 'carnal-storage-button', 1);

	var closeLayout = $('<div class="carnal-storage-action-layout"/>');
	actionRow.append(closeLayout);
	closeLayout.createTextButton("Not now", function ()
	{
		SQ.call(self.mSQHandle, 'onClosePressed');
	}, 'carnal-storage-button', 1);
};

CarnalStorageScreen.prototype.show = function (_data)
{
	this.mAmount = 1;
	this.updateData(_data);
	MSUUIScreen.prototype.show.call(this);
};

CarnalStorageScreen.prototype.updateData = function (_data)
{
	this.mData = _data;

	// Fall back to the first sacrifice you can still afford.
	if (this.getModeData(this.mMode).MaxEnergy <= 0)
	{
		for (var i = 0; i < CarnalStorageScreen.Modes.length; i++)
		{
			if (this.getModeData(CarnalStorageScreen.Modes[i]).MaxEnergy > 0)
			{
				this.mMode = CarnalStorageScreen.Modes[i];
				break;
			}
		}
	}

	this.setAmount(this.mAmount);
};

CarnalStorageScreen.prototype.getModeData = function (_mode)
{
	if (this.mData === null || !(_mode in this.mData)) return { MaxEnergy: 0, PerEnergy: 0, Fixed: false };
	return this.mData[_mode];
};

CarnalStorageScreen.prototype.getMaxEnergy = function ()
{
	return this.getModeData(this.mMode).MaxEnergy;
};

CarnalStorageScreen.prototype.selectMode = function (_mode)
{
	this.mMode = _mode;
	this.setAmount(this.mAmount);
};

CarnalStorageScreen.prototype.changeAmount = function (_delta)
{
	this.setAmount(this.mAmount + _delta);
};

CarnalStorageScreen.prototype.setAmount = function (_amount)
{
	var mode = this.getModeData(this.mMode);
	this.mAmount = mode.Fixed ? mode.MaxEnergy : Math.max(1, Math.min(mode.MaxEnergy, _amount));
	this.render();
};

CarnalStorageScreen.prototype.render = function ()
{
	if (this.mData === null) return;

	var data = this.mData;
	var self = this;
	var mode = this.getModeData(this.mMode);
	var canSacrifice = mode.MaxEnergy > 0;

	var fullyUnleashed = data.Stacks >= data.MaxStacks;
	this.mStatus.html(data.Name + ': <span class="carnal-storage-energy">' + data.Energy + ' energy</span>'
		+ ' &nbsp;|&nbsp; Damage +' + (data.Stacks * data.DamagePerStack + data.Overflow * data.OverflowDamage) + '%'
		+ ' (unleashed ' + data.Stacks + '/' + data.MaxStacks
		+ (data.Overflow > 0 ? ', overflow +' + (data.Overflow * data.OverflowDamage) + '%' : '') + ')'
		+ (fullyUnleashed ? '<br/>Overflow: +' + data.OverflowDamage + '% damage every ' + data.OverflowCost + ' energy (next in ' + (data.OverflowCost - data.Energy) + ')' : ''));

	CarnalStorageScreen.Modes.forEach(function (_mode)
	{
		var button = self.mModeButtons[_mode];
		button.enableButton(self.getModeData(_mode).MaxEnergy > 0);
		button.toggleClass('carnal-storage-selected', _mode === self.mMode);
	});

	if (mode.Fixed)
	{
		this.mAmountRow.addClass('carnal-storage-hidden');
	}
	else
	{
		this.mAmountRow.removeClass('carnal-storage-hidden');
		this.mAmountLabel.html(canSacrifice ? (this.mAmount + ' energy') : '-');
		this.mMinusButton.enableButton(canSacrifice && this.mAmount > 1);
		this.mPlusButton.enableButton(canSacrifice && this.mAmount < mode.MaxEnergy);
		this.mMaxButton.enableButton(canSacrifice && this.mAmount < mode.MaxEnergy);
	}

	var cost;
	if (!canSacrifice)
	{
		cost = 'You have nothing left to sacrifice.';
	}
	else if (this.mMode === 'Fatigue')
	{
		cost = 'Gain ' + (this.mAmount * mode.PerEnergy) + ' fatigue (' + mode.Current + '/' + mode.Max + ') for ' + this.mAmount + ' energy.';
	}
	else if (this.mMode === 'Blood')
	{
		cost = 'Lose ' + (this.mAmount * mode.PerEnergy) + ' hitpoints (' + mode.Current + '/' + mode.Max + ') for ' + this.mAmount + ' energy.';
	}
	else
	{
		cost = 'Suffer a random minor injury for ' + mode.MaxEnergy + ' energy.';
	}
	this.mCostLabel.html(cost);

	this.mSacrificeButton.enableButton(canSacrifice);

	var canUnleash = data.Energy >= data.UnleashCost && data.Stacks < data.MaxStacks;
	this.mUnleashButton.changeButtonText(data.Stacks >= data.MaxStacks
		? 'Fully unleashed'
		: 'Unleash +' + data.DamagePerStack + '% (' + data.UnleashCost + ')');
	this.mUnleashButton.enableButton(canUnleash);
};

registerScreen("CarnalStorageScreen", new CarnalStorageScreen());
