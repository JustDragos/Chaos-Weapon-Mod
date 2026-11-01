"use strict";

// The Frozen Eye: choose the brothers to sacrifice for Chaos Mind.
// Backend: scripts/mods/chaos_mind/altar_screen.nut.
var ChaosMindAltarScreen = function ()
{
	MSUUIScreen.call(this);
	this.mID = "ChaosMindAltarScreen";
	this.mData = null;
	this.mChosen = {};

	this.mList = null;
	this.mCounter = null;
	this.mOfferButton = null;
};

ChaosMindAltarScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(ChaosMindAltarScreen.prototype, 'constructor', {
	value: ChaosMindAltarScreen,
	enumerable: false,
	writable: true
});

ChaosMindAltarScreen.prototype.createDIV = function (_parentDiv)
{
	var self = this;

	this.mContainer = $('<div class="chaos-altar-screen display-none"/>');
	_parentDiv.append(this.mContainer);

	var dialog = $('<div class="chaos-altar-dialog"/>');
	this.mContainer.append(dialog);

	var header = $('<div class="chaos-altar-header"/>');
	dialog.append(header);
	header.append($('<img class="chaos-altar-eye" src="' + Path.GFX + 'skills/chaos_mind/carnal_storage.png"/>'));
	header.append($('<div class="chaos-altar-title title-font-very-big font-bold font-bottom-shadow font-color-title">The Frozen Eye</div>'));

	dialog.append($('<div class="chaos-altar-hint text-font-normal font-color-description">Choose who walks to the blade.</div>'));

	this.mList = $('<div class="chaos-altar-list"/>');
	dialog.append(this.mList);

	this.mCounter = $('<div class="chaos-altar-counter title-font-big font-bold font-color-title"/>');
	dialog.append(this.mCounter);

	var actions = $('<div class="chaos-altar-actions"/>');
	dialog.append(actions);

	var offerLayout = $('<div class="chaos-altar-button-layout"/>');
	actions.append(offerLayout);
	this.mOfferButton = offerLayout.createTextButton("Offer them", function ()
	{
		SQ.call(self.mSQHandle, 'onOfferPressed', self.getChosenIDs());
	}, 'chaos-altar-button', 1);

	var closeLayout = $('<div class="chaos-altar-button-layout"/>');
	actions.append(closeLayout);
	closeLayout.createTextButton("Not now", function ()
	{
		SQ.call(self.mSQHandle, 'onClosePressed');
	}, 'chaos-altar-button', 1);
};

ChaosMindAltarScreen.prototype.show = function (_data)
{
	this.mData = _data;
	this.mChosen = {};
	this.renderList();
	this.render();
	MSUUIScreen.prototype.show.call(this);
};

ChaosMindAltarScreen.prototype.getChosenIDs = function ()
{
	var ids = [];
	for (var id in this.mChosen)
	{
		if (this.mChosen[id] === true) ids.push(parseInt(id, 10));
	}
	return ids;
};

ChaosMindAltarScreen.prototype.countChosen = function ()
{
	return this.getChosenIDs().length;
};

ChaosMindAltarScreen.prototype.toggle = function (_id, _row)
{
	if (this.mChosen[_id] === true)
	{
		delete this.mChosen[_id];
		_row.removeClass('is-chosen');
	}
	else if (this.countChosen() < this.mData.Required)
	{
		this.mChosen[_id] = true;
		_row.addClass('is-chosen');
	}
	this.render();
};

ChaosMindAltarScreen.prototype.renderList = function ()
{
	var self = this;
	this.mList.empty();

	this.mData.Brothers.forEach(function (_bro)
	{
		var row = $('<div class="chaos-altar-row text-font-normal"/>');
		row.append($('<span class="chaos-altar-name font-color-title"/>').text(_bro.Name));
		row.append($('<span class="chaos-altar-info font-color-description"/>').text('Level ' + _bro.Level + ' ' + _bro.Background));
		row.on('click', function ()
		{
			self.toggle(_bro.ID, row);
		});
		self.mList.append(row);
	});
};

ChaosMindAltarScreen.prototype.render = function ()
{
	var count = this.countChosen();
	var required = this.mData.Required;
	this.mCounter.text('Chosen ' + count + ' / ' + required);
	this.mOfferButton.enableButton(count === required);
	this.mList.toggleClass('is-full', count >= required);
};

registerScreen("ChaosMindAltarScreen", new ChaosMindAltarScreen());
