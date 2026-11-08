import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { SearchController } from 'resource:///org/gnome/shell/ui/searchController.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

// TEMPORARY instrumentation while confirming the fix below actually works - every
// line is prefixed so it's easy to grep out of `journalctl --user` afterwards:
//   journalctl --user -b 0 | grep 'DOS-DEBUG'
// Remove this block and the dbg(...) calls once confirmed.
const DEBUG = true;
function dbg(msg) {
    if (DEBUG)
        console.log(`DOS-DEBUG: ${msg}`);
}

// Root cause, confirmed by logging actual state instead of guessing from source
// reading: by the time this module is even imported, Main.overview._shownState is
// already "SHOWING" - the overview's own "showing" signal already fired and ran
// its course before our (or Dash to Dock's, or ArcMenu's) code got a chance to run
// at all. This matches a known, still-open upstream GNOME 50 regression (e.g.
// ubuntu/dash-to-dock#2582, "Disabling 'Show overview on startup' not working on
// gnome 50" - also hits dash-to-panel independently), not anything specific to
// this config. Every previous attempt here waited for a future "showing" emission,
// which is why none of them worked: for the startup case specifically, that
// emission already happened.
//
// The actual fix: check the CURRENT state immediately in enable() and hide() right
// then if it's already under way, instead of only listening for a future signal.
// The "showing" listener stays too, to cover any boot where timing happens to
// differ and the signal hasn't fired yet when we get here.
export default class DisableOverviewSearchExtension extends Extension {
    enable() {
        dbg(`enable() called; Main.layoutManager._startingUp=${Main.layoutManager._startingUp}, ` +
            `Main.overview._shownState=${Main.overview._shownState}`);

        this._original = SearchController.prototype._shouldTriggerSearch;
        SearchController.prototype._shouldTriggerSearch = () => false;

        this._showingId = Main.overview.connect('showing', () => {
            dbg(`'showing' fired; Main.layoutManager._startingUp=${Main.layoutManager._startingUp}`);
            this._suppressIfStartingUp();
        });

        // Catches the case where "showing" already fired before we got here.
        this._suppressIfStartingUp();
    }

    _suppressIfStartingUp() {
        this._applyHidden();

        if (Main.layoutManager._startingUp && Main.overview._shownState !== 'HIDDEN') {
            dbg(`forcing overview hidden; _shownState was ${Main.overview._shownState}`);
            Main.overview.hide();
            dbg(`after hide(): _shownState=${Main.overview._shownState}`);
        }
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
