-- Non-keybind user config. Unlike binds-user.lua, the DMS keybind editor
-- never touches this file - it only round-trips hl.bind/hl.unbind lines in
-- binds-user.lua, rewriting it wholesale on every save and silently
-- dropping anything else that used to live there (confirmed the hard way:
-- this is exactly what happened to the polkit-agent/QT6 lines originally
-- placed in binds-user.lua).

-- Hyprland has no built-in polkit auth agent (unlike Plasma) - without one,
-- anything needing authentication just silently fails. @hyprpolkitagent@ is
-- substituted with the real Nix store path by modules/hyprland.nix.
hl.on("hyprland.start", function()
	hl.exec_cmd("@hyprpolkitagent@")
end)

-- hyprland.lua's own DMS_STARTUP block sets both of these to "gtk3" -
-- home-manager's qt.platformTheme sets QT_QPA_PLATFORMTHEME=qt5ct as a
-- session variable, but that's set before Hyprland starts; hl.env() in
-- hyprland.lua's startup block runs afterward and overwrites it for every
-- process Hyprland spawns, same for the Qt6-specific var which home-manager
-- has no equivalent option for at all. Confirmed live: ghostty/dms processes
-- spawned by Hyprland had QT_QPA_PLATFORMTHEME=gtk3 despite the session
-- variable being set correctly - these calls are what actually reach child
-- processes. Plain top-level calls, not inside the startup hook, so they
-- re-apply on every reload rather than just once per Hyprland process
-- lifetime.
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_QPA_PLATFORMTHEME_QT6", "qt6ct")

-- Neither of the above, nor home-manager's own home.sessionVariables,
-- actually reach DMS: it runs as a systemd user service now
-- (programs.dank-material-shell.systemd.enable), and systemd services
-- inherit systemd's OWN user-manager environment block - a completely
-- separate thing from login-shell environment (`/etc/profile.d/hm-session-
-- vars.sh`, which only shells source) or Hyprland's own per-child env.
-- Confirmed live: `systemctl --user show-environment` had
-- QT_QPA_PLATFORMTHEME=qt5ct even though a login shell correctly saw
-- qt6ct and DMS kept rejecting its own QT_QPA_PLATFORMTHEME check
-- (warnIfMissingQtTheme in its own WallpaperColorsTab.qml) as a result.
-- This is the one thing that actually reaches systemd user services.
hl.on("hyprland.start", function()
	hl.exec_cmd("systemctl --user set-environment QT_QPA_PLATFORMTHEME=qt6ct QT_QPA_PLATFORMTHEME_QT6=qt6ct")
end)

-- With no explicit monitor/workspace binding, Hyprland just assigns the
-- next free workspace to each monitor in connection order - DP-1 (primary)
-- got 1, HDMI-A-1 got 2 by sheer luck of being detected second. Binding
-- HDMI-A-1 to workspace 10 persistently gives it a fixed, predictable slot
-- instead of silently eating into the 1-9 range shared with the main
-- monitor. Monitor name confirmed live via `hyprctl monitors`.
--
-- `persistent` alone only reserves workspace 10 for this monitor (keeps it
-- alive when empty, anything sent there lands here) - it does NOT stop
-- Hyprland's separate built-in "assign the next free workspace to each
-- monitor at connect time" logic, which is a different code path entirely
-- and kept handing HDMI-A-1 workspace 2 on every session start regardless
-- of this rule (confirmed live via `hyprctl workspacerules` showing
-- `default: <unset>`). `default = true` is what actually makes workspace 10
-- the one the monitor opens on, instead of that auto-picked 2.
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1", persistent = true, default = true })

-- DMS's generated hyprland.lua sets follow_mouse = 0 (click-to-focus only)
-- by default - confirmed live via `hyprctl getoption input:follow_mouse`.
-- 1 is strict focus-follows-mouse: hovering a window focuses it immediately.
hl.config({ input = { follow_mouse = 1 } })
