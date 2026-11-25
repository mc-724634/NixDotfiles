-- Your keybinds. dms setup never overwrites this file.
-- Loaded after binds.lua: binding a stock key here replaces it, hl.unbind("SUPER + X") frees it.
-- Saving in the DMS keybind editor rewrites this file and keeps only hl.bind/hl.unbind lines.

hl.unbind("SUPER + CTRL + W")
hl.bind("SUPER + CTRL + W", hl.dsp.exec_cmd("helium --incognito"), { description = "New Helium Private Window" })
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.exec_cmd("helium"), { description = "New Helium Window" })
hl.unbind("SUPER + ALT + space")
hl.bind("SUPER + ALT + space", hl.dsp.window.float({ action = "toggle" }), { description = "Float/unfloat window" })
hl.unbind("SUPER + CTRL + space")
hl.unbind("SUPER + SHIFT + T")
hl.unbind("SUPER + E")
hl.bind("SUPER + E", hl.dsp.exec_cmd("nautilus --new-window"), { description = "New Nautilus Window" })
