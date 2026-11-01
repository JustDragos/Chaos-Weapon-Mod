"use strict";

// Small message window for hotkey notices (where is The Frozen Eye, etc.).
// Unlike MSU's popup it closes completely instead of shrinking to a badge.
// Backend: scripts/mods/chaos_mind/notice_screen.nut.
var ChaosMindNoticeScreen = function ()
{
	MSUUIScreen.call(this);
	this.mID = "ChaosMindNoticeScreen";
	this.mTitle = null;
	this.mBody = null;
};

ChaosMindNoticeScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(ChaosMindNoticeScreen.prototype, 'constructor', {
	value: ChaosMindNoticeScreen,
	enumerable: false,
	writable: true
});

ChaosMindNoticeScreen.prototype.createDIV = function (_parentDiv)
{
	var self = this;

	this.mContainer = $('<div class="chaos-notice-screen display-none"/>');
	_parentDiv.append(this.mContainer);

	var dialog = $('<div class="chaos-notice-dialog"/>');
	this.mContainer.append(dialog);

	this.mTitle = $('<div class="chaos-notice-title title-font-big font-bold font-bottom-shadow font-color-title"/>');
	dialog.append(this.mTitle);

	this.mBody = $('<div class="chaos-notice-body text-font-normal font-color-description"/>');
	dialog.append(this.mBody);

	var okLayout = $('<div class="chaos-notice-button-layout"/>');
	dialog.append(okLayout);
	okLayout.createTextButton("OK", function ()
	{
		SQ.call(self.mSQHandle, 'onClosePressed');
	}, 'chaos-notice-button', 1);
};

ChaosMindNoticeScreen.prototype.show = function (_data)
{
	this.mTitle.text(_data.Title);
	this.mBody.empty();

	var body = this.mBody;
	_data.Lines.forEach(function (_line)
	{
		body.append($('<div class="chaos-notice-line"/>').text(_line));
	});

	MSUUIScreen.prototype.show.call(this);
};

registerScreen("ChaosMindNoticeScreen", new ChaosMindNoticeScreen());
