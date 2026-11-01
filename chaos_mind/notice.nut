// Hotkey notices: a small window that closes completely (MSU's popup shrinks to a badge instead).
// Also used by Blacksmith's Workshop's Ctrl+B when this mod is installed.
::ChaosMind.Notice <- {
    Screen = null,

    // Shows _lines under _title; if a notice is already open, closes it instead (toggle).
    // Returns true so the hotkey isn't passed on.
    function toggle( _title, _lines )
    {
        if (this.Screen == null)
        {
            return false;
        }

        if (this.Screen.isShowing())
        {
            this.Screen.hide();
            return true;
        }

        this.Screen.show({ Title = _title, Lines = _lines });
        return true;
    }

    function close()
    {
        if (this.Screen != null && this.Screen.isShowing())
        {
            this.Screen.hide();
        }
    }
};

::ChaosMind.Notice.Screen = ::new("scripts/mods/chaos_mind/notice_screen");
::MSU.UI.registerConnection(::ChaosMind.Notice.Screen);
::Hooks.registerJS("ui/mods/chaos_mind/notice.js");
::Hooks.registerCSS("ui/mods/chaos_mind/notice.css");
