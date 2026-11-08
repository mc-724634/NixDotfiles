import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import { SearchController } from 'resource:///org/gnome/shell/ui/searchController.js';

// Typing in the overview is routed to search by SearchController._onStageKeyPress,
// which (unless the key is Escape) asks _shouldTriggerSearch whether the keystroke
// should start a search; hiding the search entry's actor (what other "hide search"
// extensions do) doesn't touch this at all, so search still silently activates
// and the entry reappears the moment you type. Overriding _shouldTriggerSearch
// itself to always say no is the actual point where typing stops doing anything -
// Escape and the Tab/arrow keynav handled in overviewControls.js are untouched.
export default class DisableOverviewSearchExtension extends Extension {
    enable() {
        this._original = SearchController.prototype._shouldTriggerSearch;
        SearchController.prototype._shouldTriggerSearch = () => false;
    }

    disable() {
        SearchController.prototype._shouldTriggerSearch = this._original;
        this._original = null;
    }
}
