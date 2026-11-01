"use strict";

// Chaos Guide window: chapters on the left, the chosen chapter's text on the right (scrolls).
// Backend: scripts/mods/chaos_mind/guide_screen.nut; text from ::ChaosMind.Guide.getChapters().
// In a chapter's lines, "# " starts a heading, "- " a bullet, anything else is a paragraph.
var ChaosMindGuideScreen = function ()
{
	MSUUIScreen.call(this);
	this.mID = "ChaosMindGuideScreen";
	this.mTitle = null;
	this.mIndex = null;
	this.mPage = null;
	this.mChapters = [];
	this.mCurrent = 0;
};

ChaosMindGuideScreen.prototype = Object.create(MSUUIScreen.prototype);
Object.defineProperty(ChaosMindGuideScreen.prototype, 'constructor', {
	value: ChaosMindGuideScreen,
	enumerable: false,
	writable: true
});

ChaosMindGuideScreen.prototype.createDIV = function (_parentDiv)
{
	var self = this;

	this.mContainer = $('<div class="chaos-guide-screen display-none"/>');
	_parentDiv.append(this.mContainer);

	var dialog = $('<div class="chaos-guide-dialog"/>');
	this.mContainer.append(dialog);

	this.mTitle = $('<div class="chaos-guide-title title-font-big font-bold font-bottom-shadow font-color-title"/>');
	dialog.append(this.mTitle);

	var columns = $('<div class="chaos-guide-columns"/>');
	dialog.append(columns);

	this.mIndex = $('<div class="chaos-guide-index"/>');
	columns.append(this.mIndex);

	this.mPage = $('<div class="chaos-guide-page text-font-normal font-color-description"/>');
	columns.append(this.mPage);

	var closeLayout = $('<div class="chaos-guide-button-layout"/>');
	dialog.append(closeLayout);
	closeLayout.createTextButton("Close", function ()
	{
		SQ.call(self.mSQHandle, 'onClosePressed');
	}, 'chaos-guide-button', 1);
};

ChaosMindGuideScreen.prototype.show = function (_data)
{
	var self = this;

	this.mTitle.text(_data.Title);
	this.mChapters = _data.Chapters;
	this.mIndex.empty();

	this.mChapters.forEach(function (_chapter, _i)
	{
		var entry = $('<div class="chaos-guide-entry text-font-normal font-color-description"/>').text(_chapter.Title);
		entry.click(function ()
		{
			self.showChapter(_i);
		});
		self.mIndex.append(entry);
	});

	this.showChapter(this.mCurrent < this.mChapters.length ? this.mCurrent : 0);
	MSUUIScreen.prototype.show.call(this);
};

ChaosMindGuideScreen.prototype.showChapter = function (_i)
{
	var chapter = this.mChapters[_i];
	var page = this.mPage;

	this.mCurrent = _i;
	this.mIndex.children().removeClass('is-selected');
	this.mIndex.children().eq(_i).addClass('is-selected');

	page.empty();
	page.append($('<div class="chaos-guide-chapter title-font-normal font-bold font-color-title"/>').text(chapter.Title));

	chapter.Lines.forEach(function (_line)
	{
		if (_line.indexOf("# ") === 0)
		{
			page.append($('<div class="chaos-guide-heading font-bold font-color-title"/>').text(_line.substring(2)));
		}
		else if (_line.indexOf("- ") === 0)
		{
			page.append($('<div class="chaos-guide-bullet"/>').text(_line.substring(2)));
		}
		else
		{
			page.append($('<div class="chaos-guide-paragraph"/>').text(_line));
		}
	});

	page.scrollTop(0);
};

registerScreen("ChaosMindGuideScreen", new ChaosMindGuideScreen());
