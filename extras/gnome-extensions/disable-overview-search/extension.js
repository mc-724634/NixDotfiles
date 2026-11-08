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
// This is also where the overview showing on login gets suppressed. Confirmed via
// live logging (not just source reading): by the time this module is even
// imported, Main.overview._shownState is already "SHOWING" - its own "showing"
// signal already fired and ran its course before any extension code (ours, Dash
// to Dock's, ArcMenu's) got a chance to run at all. That matches a known, still-
// open upstream GNOME 50 regression (ubuntu/dash-to-dock#2582, "Disabling 'Show
// overview on startup' not working on gnome 50" - independently hits dash-to-panel
// too), not anything specific to this config. So instead of only listening for a
// future "showing" emission (which is what Dash to Dock/ArcMenu's own settings do,
// and why they stopped working here), _suppressIfStartingUp() also runs
// immediately in enable() to catch the signal having already fired before we even
// loaded. The listener stays too, in case timing differs on some boot and it
// genuinely hasn't fired yet when we get here.
export default class DisableOverviewSearchExtension extends Extension {
    enable() {
        this._original = SearchController.prototype._shouldTriggerSearch;
        SearchController.prototype._shouldTriggerSearch = () => false;

        this._showingId = Main.overview.connect('showing', () => this._suppressIfStartingUp());

        this._suppressIfStartingUp();
    }

    _suppressIfStartingUp() {
        this._applyHidden();

        if (Main.layoutManager._startingUp && Main.overview._shownState !== 'HIDDEN')
            Main.overview.hide();
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
