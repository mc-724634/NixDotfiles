import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { SearchController } from 'resource:///org/gnome/shell/ui/searchController.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

// Typing in the overview is routed to search by SearchController._onStageKeyPress,
// which (unless the key is Escape) asks _shouldTriggerSearch whether the keystroke
// should start a search. Overriding it to always say no stops that path, but it
// doesn't touch the search entry widget itself: clicking directly into it still
// focuses it and lets you type/search normally.
//
// ControlsManagerLayout.vfunc_allocate (overviewControls.js) gives the entry's
// wrapping St.Bin (Main.overview.searchEntry.get_parent()) its height by calling
// get_preferred_height() on it every allocation, so hiding the entry alone leaves
// a blank gap where it used to be. Overriding get_preferred_height on the bin to
// report 0 is what actually collapses that space; hiding + disabling the entry's
// own reactivity/focusability is what stops it from being clicked into at all.
//
// Applying that on an "overview showing" event rather than unconditionally in
// enable() matters: enable() runs very early in the session, and reaching into
// Main.overview.searchEntry that early forces the overview to realize/construct
// itself, which on its own was enough to make the overview visible on login.
//
// It's also the place to deal with the overview literally showing on login, a
// problem that predates this extension: Dash to Dock and ArcMenu both try to
// suppress that themselves (their own "don't show overview on startup" settings),
// but their approach is pre-emptive - they flip Main.sessionMode.hasOverview to
// false before GNOME's own startup-animation code checks it, which only works if
// their enable() runs before that check does. Extension enabling
// (ui/extensionSystem.js's _enableAllExtensions) is an async sequence that
// interleaves with the independent (also async) startup-animation/background-load
// chain in main.js/layout.js, so no amount of reordering enabled-extensions
// reliably wins that race - confirmed by testing it, it didn't help.
//
// Reacting instead of pre-empting sidesteps the race entirely: GNOME's own
// Overview._showDone() explicitly handles hide() being called while still in the
// SHOWING state ("Handle any calls to hide* while we were showing"), so calling
// Main.overview.hide() from inside our own "showing" handler is both supported and
// not timing-sensitive - it runs after the overview has already decided to show,
// however late that decision was made, and cancels it there.
export default class DisableOverviewSearchExtension extends Extension {
    enable() {
        this._original = SearchController.prototype._shouldTriggerSearch;
        SearchController.prototype._shouldTriggerSearch = () => false;

        this._showingId = Main.overview.connect('showing', () => {
            this._applyHidden();

            if (Main.layoutManager._startingUp)
                Main.overview.hide();
        });
    }

    _applyHidden() {
        if (this._entry)
            return;

        const entry = Main.overview.searchEntry;
        const bin = entry.get_parent();

        this._entry = entry;
        this._bin = bin;
        this._origBinGetPreferredHeight = bin.get_preferred_height;

        entry.hide();
        entry.reactive = false;
        entry.can_focus = false;

        bin.get_preferred_height = () => [0, 0];
        bin.hide();
        bin.queue_relayout();
    }

    disable() {
        SearchController.prototype._shouldTriggerSearch = this._original;
        this._original = null;

        if (this._showingId) {
            Main.overview.disconnect(this._showingId);
            this._showingId = null;
        }

        if (this._entry) {
            this._entry.show();
            this._entry.reactive = true;
            this._entry.can_focus = true;
            this._entry = null;
        }

        if (this._bin) {
            this._bin.get_preferred_height = this._origBinGetPreferredHeight;
            this._bin.show();
            this._bin.queue_relayout();
            this._bin = null;
        }
    }
}
