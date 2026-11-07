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
//
// Because we immediately unmaximize() the window after tiling it, Mutter's
// maximized flags go back to false, so the app's own decoration never thinks
// the window is "really" maximized. That means clicking the button again
// sends another maximize request rather than a restore one. We track each
// window's pre-tile geometry ourselves and treat that second click as a
// toggle: it restores the window to its original size/position instead of
// re-tiling it to the same spot.
export default class MaximizeToTileExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._windowSignals = new Map();
        this._windowState = new Map();

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
        this._windowState.clear();

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
        this._windowState.set(window, { tiled: false, normalRect: null });
    }

    _untrack(window) {
        const ids = this._windowSignals.get(window);
        if (!ids)
            return;

        ids.forEach((id) => window.disconnect(id));
        this._windowSignals.delete(window);
        this._windowState.delete(window);
    }

    _onMaximizedChanged(window) {
        // Only act once the window is FULLY maximized (both axes); half-tiled
        // (Super+Left/Right-style) states set only one of the two flags.
        if (!window.maximizedHorizontally || !window.maximizedVertically)
            return;

        const state = this._windowState.get(window);
        if (!state)
            return;

        if (state.tiled) {
            // Already tiled by us, so this maximize request is really the
            // user asking to restore: unmaximize and put it back where it
            // was before it was first tiled.
            window.unmaximize(Meta.MaximizeFlags.BOTH);
            if (state.normalRect) {
                window.move_resize_frame(
                    false,
                    state.normalRect.x,
                    state.normalRect.y,
                    state.normalRect.width,
                    state.normalRect.height,
                );
            }
            state.tiled = false;
            return;
        }

        const gap = this._settings.get_int('gap');
        const workArea = window.get_work_area_for_monitor(window.get_monitor());

        // unmaximize() snaps the window back to Mutter's own record of its
        // pre-maximize geometry; grab it before move_resize_frame overwrites
        // that record with the gapped tile rect below.
        window.unmaximize(Meta.MaximizeFlags.BOTH);
        const normalRect = window.get_frame_rect();
        state.normalRect = {
            x: normalRect.x,
            y: normalRect.y,
            width: normalRect.width,
            height: normalRect.height,
        };

        window.move_resize_frame(
            false,
            workArea.x + gap,
            workArea.y + gap,
            workArea.width - gap * 2,
            workArea.height - gap * 2,
        );
        state.tiled = true;
    }
}
