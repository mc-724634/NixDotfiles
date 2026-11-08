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
export default class DisableOverviewSearchExtension extends Extension {
    enable() {
        this._original = SearchController.prototype._shouldTriggerSearch;
        SearchController.prototype._shouldTriggerSearch = () => false;

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
