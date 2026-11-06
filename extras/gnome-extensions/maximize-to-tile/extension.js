import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import Meta from 'gi://Meta';

// GNOME gives extensions no hook on the titlebar maximize button itself (it's
// handled inside each app's own client-side decoration, invisible to the
// Shell). The only thing we CAN observe is the resulting Meta.Window state
// change, which fires the same way no matter what triggered it: the button,
// double-click-titlebar, a keybinding or the window menu. So instead of a
// true edge-to-edge maximize, every one of those is turned into a gapped
// resize to the monitor's work area, which is what Tiling Shell itself does
// when you drag a window to the top edge.
export default class MaximizeToTileExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._windowSignals = new Map();

        this._windowCreatedId = global.display.connect(
            'window-created',
            (_display, window) => this._track(window),
        );

        global.get_window_actors().forEach((actor) => this._track(actor.meta_window));
    }

    disable() {
        global.display.disconnect(this._windowCreatedId);
        this._windowCreatedId = null;

        for (const [window, ids] of this._windowSignals)
            ids.forEach((id) => window.disconnect(id));
        this._windowSignals.clear();

        this._settings = null;
    }

    _track(window) {
        if (!window || this._windowSignals.has(window))
            return;

        const onChange = () => this._onMaximizedChanged(window);
        const ids = [
            window.connect('notify::maximized-horizontally', onChange),
            window.connect('notify::maximized-vertically', onChange),
            window.connect('unmanaging', () => this._untrack(window)),
        ];
        this._windowSignals.set(window, ids);
    }

    _untrack(window) {
        const ids = this._windowSignals.get(window);
        if (!ids)
            return;

        ids.forEach((id) => window.disconnect(id));
        this._windowSignals.delete(window);
    }

    _onMaximizedChanged(window) {
        // Only act once the window is FULLY maximized (both axes); half-tiled
        // (Super+Left/Right-style) states set only one of the two flags.
        if (!window.maximizedHorizontally || !window.maximizedVertically)
            return;

        const gap = this._settings.get_int('gap');
        const workArea = window.get_work_area_for_monitor(window.get_monitor());

        window.unmaximize(Meta.MaximizeFlags.BOTH);
        window.move_resize_frame(
            false,
            workArea.x + gap,
            workArea.y + gap,
            workArea.width - gap * 2,
            workArea.height - gap * 2,
        );
    }
}
