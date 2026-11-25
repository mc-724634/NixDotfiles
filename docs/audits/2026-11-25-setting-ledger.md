# Setting-by-setting ledger — Phase 4 forensic audit (2026-11-25)

Scope and method are explained in `2026-11-25-phase4-audit.md`. This file is the
raw ledger: one entry per explicitly-authored setting (or identical group of
settings), in file order. DMS/Hyprland files that are vendored verbatim from
`dms setup` and never hand-edited (`binds.lua`, `windowrules.lua`, `colors.lua`,
`layout.lua`, `outputs.lua`, `cursor.lua`, `animations.lua`, `input.lua`) are
inventoried at the file level in the main report, not line-by-line here — they
are upstream defaults, not our settings. `user-config.lua` and `binds-user.lua`
*are* hand-authored and get full entries.

Legend for **Verification**: RUNTIME = checked against the live system this
session; GENERATED = checked against a file Nix/DMS actually generated; EVAL =
checked with `nix eval`/`nix flake check`; BUILD = implied by a successful
`nixos-rebuild build`/the `result` symlink; SOURCE = checked against module or
upstream source; DOC = checked against upstream documentation; NONE = not
independently verified this pass.

---

## configuration.nix

### `nixpkgs.config.allowUnfree = true;`
- **Location**: configuration.nix:9
- **Origin**: nixpkgs
- **Default**: `false`
- **Purpose**: permits unfree packages (helium overlay aside, needed for e.g. `steam`, `vscode`, `discord`, `unrar`).
- **Dependencies**: every unfree package declared in `home.nix`/`configuration.nix`; without it, evaluation fails outright for those.
- **Interactions**: none within this repo; global nixpkgs config.
- **Side effects**: none beyond allowing the build to proceed.
- **Hardware relevance**: none.
- **Research**: nixpkgs manual §"Installing unfree packages".
- **Verification**: BUILD (the `result` symlink exists and contains unfree packages, e.g. `vscode`, `steam`, `discord`, so this is in effect).
- **Assessment**: Keep. Required for packages already in daily use; no narrower allowlist was requested and `allowUnfreePredicate` would just be extra surface for no benefit here.

### `nixpkgs.overlays` — helium overlay
- **Location**: configuration.nix:12
- **Origin**: `helium-flake` input
- **Purpose**: provides the `helium` browser package/module.
- **Dependencies**: `programs.helium.enable` (line 260).
- **Verification**: RUNTIME — `pgrep -af helium` shows live Helium processes this session.
- **Assessment**: Keep.

### `blender-rocm` overlay
- **Location**: configuration.nix:13-22
- **Origin**: custom overlay, hand-authored
- **Purpose**: wraps `pkgsRocm.blender` with `LD_PRELOAD` for `libamd_comgr.so.3` so Blender's Cycles renderer can use this machine's RX 6600 XT via ROCm/HIP.
- **Dependencies**: `hardware.amdgpu.opencl.enable = true;` (line 123); consumed by `home.nix`'s `blender-rocm` package entry.
- **Interactions**: RX 6600 XT (Navi 23, RDNA2) is on AMD's officially-supported ROCm list for recent ROCm releases (gfx1032); confirmed by `rev c1` / `Navi 23` from `lspci -nnk`.
- **Hardware relevance**: direct — this specific wrapper only makes sense for this GPU.
- **Research**: ROCm's own `LD_PRELOAD` requirement for `libamd_comgr` is a known, documented nixpkgs pattern for RDNA cards (visible in nixpkgs' own `blender` ROCm passthru tests).
- **Verification**: SOURCE (overlay logic read directly) + NONE for actually launching Blender and rendering with Cycles/HIP this session (not tested live — flagged below under edge cases).
- **Assessment**: Keep. Narrow, justified, undone by nothing else.

### `vencord` overlay (version bump to 1.15.16)
- **Location**: configuration.nix:24-47
- **Origin**: custom overlay, hand-authored, with inline justification referencing nixpkgs' pinned 1.15.13 and upstream issue Vendicated/Vencord#4799
- **Purpose**: fixes Discord hanging on "Starting..." after Discord's Nov 2026 rspack web-client switch, which the pinned nixpkgs Vencord predates.
- **Verification**: RUNTIME — `discord.override { withVencord = true; }` is in `home.nix`; comment states "already on nixpkgs master, not yet backported to 26.05" — NOT independently re-verified against the live nixpkgs master branch this pass (would require a network fetch of nixpkgs' current master, not performed). Historically confirmed working per `discord_vencord_setup.md` memory.
- **Assessment**: Keep until 26.05 backports ≥1.15.16, exactly as the comment states. **Follow-up for the user**: re-check whether nixos-26.05 has picked this up yet, since the overlay is pure maintenance debt once it has.

### `kdePackages.qt6ct` overlay (NUR ilya-fedin fork)
- **Location**: configuration.nix:49-62
- **Origin**: custom overlay via `nur` input
- **Purpose**: works around nixpkgs issue #489021 (nixpkgs' own `qt6ct` lacks KDE theming support).
- **Dependencies**: `qt.platformTheme.name = "qtct"` in `modules/hyprland.nix:56`.
- **Verification**: RUNTIME — confirmed live in the previous phase that the installed `qt6ct` links `kcolorscheme`/`kiconthemes` (via `ldd`/closure inspection at the time). Not re-run this pass; treating prior verification as still valid since the overlay pin hasn't changed (`flake.lock` diff not inspected for `nur` input drift this pass — see Unresolved list).
- **Assessment**: Keep.

### `boot.kernelPackages = pkgs.linuxPackages_zen;`
- **Location**: configuration.nix:66
- **Origin**: NixOS (`boot.kernelPackages`)
- **Default**: `pkgs.linuxPackages` (the LTS/stable kernel line for the channel)
- **Purpose**: tracks a more current kernel line (`zen` = mainline-tracking + a small scheduler/latency patch set) rather than the slower-moving default.
- **Verification**: RUNTIME — `uname -r` → `7.3.5-zen1`, confirms it's active, not just declared.
- **Hardware relevance**: on a Zen 3 desktop CPU + RDNA2 GPU with no exotic peripherals, newer kernels mainly help via more current `amdgpu`/`btrfs` code; no CPU-specific scheduler issue was identified that zen's patches target.
- **Research**: NONE this pass — did not inspect `linux-zen`'s actual patch list against `linuxPackages` to confirm what's materially different for this hardware vs. just "newer version number." This is an **inherited decision from an earlier session**, not something this phase re-derived from first principles.
- **Assessment**: Keep (it's working, stable, `systemctl --failed` is clean) but flagged **UNRESOLVED** on the "is this actually the best choice for this hardware vs. plain `linuxPackages_latest`" question — no regression found, no proof of net benefit established this pass either.

### `boot.kernelParams`
- **Location**: configuration.nix:67-77
- `"quiet"`, `"splash"` — origin: standard kernel/Plymouth params, suppress console boot text so Plymouth's splash is the only thing visible. Verification: RUNTIME (`cat /proc/cmdline` confirms both present).
- `"amdgpu.ppfeaturemask=0xffff7fff"` — origin: `amdgpu` kernel module parameter. Purpose: documented at length in the adjacent comment and `README.md` — clears bit `0x8000` (`PP_GFXOFF_MASK`) of the LACT-required `0xffffffff` mask, forcing GFXOFF off to stop "Failed to disable gfxoff!" dmesg spam on this RX 6600 XT. **Research**: this exact mask/bit is the documented amdgpu driver parameter (`drivers/gpu/drm/amd/pm/`); matches public reports of the same GFXOFF race on Navi 2x cards with LACT/overclocking tools enabled. **Verification**: RUNTIME — `cat /proc/cmdline` shows the param applied; `journalctl -k -b 0 | grep -i gfxoff` produced **zero matches** this session (previously it spammed) — this is a genuine, positive, re-confirmed verification, not just "assume it still works." **Assessment**: Keep, exactly as documented.

### `boot.kernel.sysctl."vm.swappiness" = 100;`
- **Location**: configuration.nix:78
- **Origin**: Linux kernel sysctl, default `60`
- **Purpose**: with zram as the *only* swap device (confirmed: `swapDevices = [];` in hardware-configuration.nix, only `/dev/zram0` from `swapon --show`), swapping is CPU-cheap (zstd-compressed RAM-to-RAM) rather than disk I/O, so biasing the kernel toward using it more aggressively frees real RAM for page cache without the latency penalty normal disk swap would carry.
- **Research**: this is the standard, widely-documented zram pairing (e.g. Fedora's own zram-generator package ships `vm.swappiness=100` as its companion recommendation) — not a blind "performance guide" copy, it's specifically conditioned on zram-as-only-swap being true here, which it is.
- **Verification**: RUNTIME — `cat /proc/sys/vm/swappiness` not explicitly re-read this pass (the kernelParams/sysctl *declaration* is confirmed in the Nix file and the system is running the built generation, so it's BUILD-level verified, not independently read from `/proc` this exact pass — logging this distinction rather than papering over it).
- **Assessment**: Keep.

### `boot.plymouth.enable = true; boot.plymouth.theme = "bgrt";`
- **Location**: configuration.nix:80-86
- **Origin**: NixOS. Default theme: `"spinner"` (stock bgrt-less spinner on generic background).
- **Purpose**: shows the motherboard/OEM boot logo (read from the firmware's ACPI BGRT table) with the spinner overlaid, instead of a generic NixOS/plain background.
- **Dependencies**: `hardware.amdgpu.initrd.enable = true` (line 122) — explicitly documented as required so amdgpu's early-KMS takeover doesn't reset the display mid-splash and kill the spinner's render loop.
- **Verification**: RUNTIME — not re-tested via an actual reboot this pass (would require interrupting the user's session); treated as NOT RE-TESTED, resting on the prior session's confirmation recorded in commit history (`35d462b Switch Plymouth theme to bgrt...`, `b830b89 Load amdgpu in initrd so Plymouth's spinner survives the GPU handoff`).
- **Assessment**: Keep. NOT RE-TESTED this pass (rebooting to verify is reasonably invasive for an audit; flagged in edge-case matrix).

### `boot.initrd.systemd.enable = true;`
- **Location**: configuration.nix:89
- **Origin**: NixOS. Default: `false` on 26.05 (opt-in, though NixOS has been moving toward making this the default upstream — confirmed still opt-in on this release by its presence here as an explicit set).
- **Purpose**: required for TPM2-backed LUKS unlock (`systemd-cryptsetup` understands `tpm2-device=auto`; the legacy initrd `cryptsetup` script does not).
- **Dependencies**: `boot.initrd.luks.devices.*.crypttabExtraOpts = [ "tpm2-device=auto" ];` (line 90-92) depends on this.
- **Verification**: RUNTIME — the machine booted and decrypted `/` without a manual passphrase prompt this session (implied by the session existing at all over LUKS root), which only works if TPM2 auto-unlock actually fired. Not independently re-tested by rebooting.
- **Hardware relevance**: direct — requires a TPM2 chip, which this machine evidently has enabled and enrolled (out of scope to re-verify TPM enrollment state this pass per the "never touch encryption" rule).
- **Assessment**: Keep, untouched (explicitly off-limits per the safety rules in the prompt).

### `boot.loader.timeout = 0;`
- **Location**: configuration.nix:94
- **Origin**: NixOS systemd-boot. Default: `5` (shows a 5s boot menu).
- **Purpose**: skip straight to the default boot entry.
- **Side effects**: no interactive window to pick an older generation at boot without holding a key (systemd-boot still allows this via a keypress during the (near-zero) window / Escape at POST, not fully eliminated, but harder).
- **Verification**: NONE this pass (not rebooted).
- **Assessment**: Keep — deliberate choice for fast boot, rollback is still possible via `nixos-rebuild --rollback` or selecting an older generation without needing the timeout.

### `boot.loader.efi.canTouchEfiVariables = true;`
- **Location**: configuration.nix:95
- **Purpose**: lets the bootloader installer write NVRAM boot entries. Required for `lanzaboote`/systemd-boot's installer to register itself with firmware.
- **Verification**: BUILD-implied (system boots via UEFI into this install).
- **Assessment**: Keep.

### `boot.loader.systemd-boot.enable = lib.mkForce false;` + `boot.lanzaboote`
- **Location**: configuration.nix:97-101
- **Origin**: `lanzaboote` flake input (Secure Boot for systemd-boot via a signed UKI chain)
- **Purpose**: Secure Boot support; `lib.mkForce false` is required because `boot.lanzaboote.enable` internally still wants `systemd-boot`'s generator but needs its own `enable` flag to be the one actually turning the loader stanza on, per lanzaboote's own module docs.
- **Dependencies**: `pkiBundle = "/var/lib/sbctl"` — an `sbctl`-managed key bundle (note: `sbctl` is also in `environment.systemPackages`, consistent).
- **Verification**: RUNTIME — `sbctl status` not re-run this pass (would be informative but wasn't executed); NONE this exact pass, SOURCE/BUILD only (system boots, which requires Secure Boot validation to have passed if SB is actually enabled in firmware — firmware-level SB enablement itself is out of scope/unverifiable from inside the OS without `mokutil`/`sbctl status`, flagged UNRESOLVED).
- **Assessment**: Keep, untouched (boot/Secure Boot off-limits per safety rules). **Flagged UNRESOLVED**: did not run `sbctl status` to confirm Secure Boot is actually `Enabled` + `Setup Mode: Disabled` in firmware this pass.

### `zramSwap`
- **Location**: configuration.nix:103-108
- `enable = true;` — Origin: NixOS. Verification: RUNTIME, `zramctl` shows `/dev/zram0` live, `swapon --show` confirms it's the active swap.
- `algorithm = "zstd";` — Default: `"lzo-rle"`. Purpose: zstd trades a bit more CPU for meaningfully better compression ratio than lzo-rle; reasonable on a 6c/12t Zen 3 CPU which has cycles to spare for this. Research: zram-generator's own docs list zstd as the generally-recommended modern choice over lzo-rle on non-embedded hardware. Verification: RUNTIME, `zramctl` confirms `ALGORITHM zstd`.
- `memoryPercent = 100;` + `memoryMax = 8 * 1024^3;` — Purpose: size zram as up to 100% of RAM, capped at 8GiB. On this 15GiB-RAM machine, 100% would be ~15GiB; the 8GiB cap is the actual binding constraint. Verification: RUNTIME — `zramctl` shows `DISKSIZE 8G`, confirming the cap (not the percentage) is what's in effect. **Assessment**: sane for 16GB nominal RAM; an 8GiB zram device is a reasonable ceiling that avoids the device alone eating half of RAM in worst-case compressed-to-uncompressed ratio scenarios.

### `hardware.graphics.enable / enable32Bit`
- **Location**: configuration.nix:111-114
- **Purpose**: Mesa (OpenGL/Vulkan) userspace drivers, with 32-bit variants for Steam/Proton/Wine.
- **Dependencies**: `programs.steam.enable` needs `enable32Bit` for 32-bit games/Proton compatibility layers.
- **Verification**: RUNTIME — `hardware.graphics.enable` is effectively confirmed by the fact that a Wayland/Hyprland GPU-accelerated session is running at all (`hyprctl` responds, DMS renders). 32-bit specifically NOT independently re-verified this pass (would need to actually launch a 32-bit Steam title).
- **Assessment**: Keep.

### `hardware.amdgpu.initrd.enable = true;`
- See Plymouth entry above — same dependency, already covered.

### `hardware.amdgpu.opencl.enable = true;`
- **Location**: configuration.nix:123
- **Purpose**: installs AMD's OpenCL ICD (ROCr/ROCm userspace), consumed by the `blender-rocm` overlay.
- **Verification**: NONE this pass (not tested by actually running `clinfo` or a ROCm workload).
- **Assessment**: Keep; flagged NOT TESTED for actual OpenCL enumeration.

### `hardware.bluetooth.enable = true;`
- **Location**: configuration.nix:126
- **Verification**: RUNTIME — `systemctl is-active bluetooth` not explicitly re-run this pass; `hardware.bluetooth.enable` implies a `bluetooth.service` unit exists, and `systemctl --failed` was clean (if it were failing, it would show here), which is at least indirect confirmation.
- **Assessment**: Keep.

### `hardware.i2c.enable = true;`
- **Location**: configuration.nix:129
- **Purpose**: loads `i2c-dev`, installs the udev rule granting user access, needed for `ddcutil`/DDC-CI monitor-brightness control.
- **Dependencies**: `ddcutil` package (line 321); consumed by DMS's brightness slider for external monitors (per the inline comment).
- **Verification**: NONE this pass (did not run `ddcutil detect` to confirm a monitor actually answers DDC/CI).
- **Assessment**: Keep; flagged NOT TESTED this pass.

### `services.lact.enable = true;` + `systemd.services.lactd.path = [ "/run/wrappers" ];`
- **Location**: configuration.nix:131-132
- **Purpose**: LACT (Linux AMDGPU Control Tool) daemon for GPU fan curves/overclocking/power limits; the explicit `path` addition makes `/run/wrappers` (setuid wrapper dir) reachable so LACT's privileged helper binaries resolve correctly.
- **Verification**: RUNTIME — `systemctl is-active lactd` not explicitly re-checked this exact pass, but `systemctl --failed` returned empty, so it is not in a failed state.
- **Assessment**: Keep.

### `services.hardware.openrgb` (`enable`, `package = openrgb-with-all-plugins`, `motherboard = "amd"`)
- **Location**: configuration.nix:134-138
- **Purpose**: RGB lighting control daemon + SDK server.
- **Verification**: RUNTIME — **directly verified this pass**: `systemctl status openrgb` shows it `active (running)`, and its SDK server is confirmed bound on `0.0.0.0:6742` via `ss -tulnp`. Cross-checked against the firewall (`iptables -L nixos-fw` has no rule opening 6742), so despite binding all interfaces, it is **not reachable from the LAN** — the system firewall's default-deny still applies. This was a genuinely new finding this pass (not previously checked in Phase 1-3).
- **Assessment**: Keep as-is. No `openFirewall` option is set (and none should be, unless the user actually wants a phone/other-host OpenRGB client to reach this machine over the network — not a stated requirement).

### `networking.hostName = "nixos";` / `networking.networkmanager.enable = true;`
- **Location**: configuration.nix:141-142
- **Verification**: RUNTIME, `hostname` / active network connectivity implied by the whole session working over network (helium browsing, Discord, etc. all functioning).
- **Assessment**: Keep.

### `services.avahi` (`enable`, `nssmdns4`, `openFirewall`, `publish.enable`, `publish.userServices`)
- **Location**: configuration.nix:144-152
- **Purpose**: mDNS/`.local` hostname resolution + service discovery (used by KDE Connect/valent discovery, network printers, etc.).
- **Verification**: RUNTIME — `ss -tulnp` confirms UDP `5353` (mDNS) listening on both `0.0.0.0` and `[::]`.
- **Assessment**: Keep.

### `programs.kdeconnect.enable = true;`
- **Location**: configuration.nix:156
- **Purpose**: opens KDE Connect's TCP/UDP 1714-1764 range, installs `kdeconnect-kde`.
- **Interactions**: **confirmed, documented, deliberate overlap** with `valent` (home.nix) — both implement the same protocol; **RUNTIME-confirmed this pass**: `ss -tulnp` shows *both* `.kdeconnectd-wr` and `.valent-wrapped` simultaneously bound to TCP+UDP `1716` (not the full 1714-1764 range — both only actually use port 1716/1717 in practice, confirmed live, refining the "1714-1764" characterization in the existing comment to what's actually observed). Whichever wins the bind first holds discovery; this was already known and accepted.
- **Assessment**: Keep (explicit prior user decision to keep both). Ledger refinement: actual observed ports are 1716 (kdeconnect, TCP+UDP) and 1716/1717 (valent, UDP 1716 + TCP 1717) — slightly different from the "both use the same ports" framing in the existing comments; worth a comment tweak but not a functional change.

### `time.timeZone = "America/New_York";` / `i18n.defaultLocale = "en_US.UTF-8";`
- **Location**: configuration.nix:159-160
- **Verification**: RUNTIME — `timedatectl`/clock shown in screenshots this session (`1:41 AM Wed 25`) is consistent with EST and the `date` command.
- **Assessment**: Keep.

### `programs.dms-greeter` (`enable`, `compositor.name = "hyprland"`, `configHome = "/home/mc"`)
- **Location**: configuration.nix:170-174
- **Purpose**: greetd-backed login screen, renders in Hyprland, syncs wallpaper/cursor/colors from the real user's config via `configHome`.
- **Verification**: NOT TESTED this pass (would require logging out, which wasn't done). Resting on prior-session confirmation.
- **Assessment**: Keep.

### `programs.hyprland.enable = true;` / `programs.hyprland.withUWSM = true;`
- **Location**: configuration.nix:175-184
- **Purpose/research**: the inline comment states Hyprland's packaged session launcher (`start-hyprland`) invokes UWSM unconditionally regardless of this flag in this nixpkgs version, and that `withUWSM = true` is what makes NixOS actually wire UWSM's systemd user units into the session's unit search path (otherwise `systemctl --user start wayland-session-bindpid@<pid>.service` — UWSM's own internal call — fails with "unit not found" and the session tears down ~10s after login).
- **Verification**: **RUNTIME-confirmed this pass, new evidence**: `ps -eo pid,comm | grep -i hyprland` shows the compositor running as `start-hyprland` (PID 2311, UWSM's wrapper) → `.Hyprland-wrapp` (PID 2316), and `systemctl --user show-environment` contains `UWSM_FINALIZE_VARNAMES=...`, which only exists when UWSM's finalize service has actually run — direct proof `withUWSM=true` is in effect and UWSM is genuinely driving the session, not just configured.
- **Assessment**: Keep. Confirmed correct, not just "builds."

### `programs.dank-material-shell` (`enable`, `enableClipboardPaste`, `enableSystemMonitoring`, `systemd.enable`)
- **Location**: configuration.nix:186-202
- **Purpose**: DMS itself; `systemd.enable=true` moves DMS from an `exec-once` Hyprland hook to a proper `Type=notify`, `Restart=on-failure` systemd user service.
- **Verification**: **RUNTIME-confirmed this pass**: `systemctl --user show dms.service -p Environment` succeeds (unit exists, is queryable), and `hyprland.lua`'s `DMS_STARTUP` block contains **no** `dms run` exec line (confirmed by direct read this pass) — matching the comment's claim that the old hook was removed to avoid a double-launch race. **Defect found**: `README.md` (lines 85-90) still describes the *old* state (exec-once launch, "systemd.enable left off") — see Findings document, this is a confirmed stale-documentation defect, not a functional one.
- **Assessment**: Keep the Nix config as-is; fix the README (done — see Findings §1).

### `fonts.packages = [ hack-font noto-fonts ];` / `fonts.fontDir.enable = true;`
- **Location**: configuration.nix:204-210
- **Purpose**: `hack-font` is the Ghostty monospace font (`modules/shell.nix:279`); `noto-fonts` for broad Unicode/emoji/CJK glyph coverage; `fontDir.enable` symlinks fonts into `/run/current-system/sw/share/X11/fonts`-style paths visible to Flatpak sandboxes.
- **Research**: NixOS manual, `fonts.fontDir` option description — confirmed this is specifically for non-Nix-aware consumers (Flatpak), matching the inline comment.
- **Gap identified**: no explicit Nerd Font / symbols font package is declared, yet `modules/shell.nix` configures Starship (which commonly renders Nerd Font glyphs for git/language icons) and the fastfetch config uses only plain text, no icon glyphs. **Not confirmed as a visual defect** (Starship can run glyph-free; not verified whether the current Starship preset actually requests Nerd Font glyphs) — flagged UNRESOLVED, needs a visual check of the actual prompt in a terminal.
- **Assessment**: Keep as-is; Nerd Font gap flagged for the user's input rather than assumed.

### `security.rtkit.enable = true;`
- **Location**: configuration.nix:213
- **Purpose**: lets PipeWire's audio threads request realtime scheduling via RealtimeKit (D-Bus) instead of needing raw `CAP_SYS_NICE`/setuid.
- **Verification**: NONE this pass (didn't check `rtkit-daemon` activity or confirm PipeWire actually holds RT priority via `chrt`/`pw-top`).
- **Assessment**: Keep; standard, correct pairing with `services.pipewire.enable`.

### `services.pipewire` (`enable`, `alsa.enable`, `alsa.support32Bit`, `pulse.enable`, `extraConfig.pipewire."10-disable-x11-bell"`)
- **Location**: configuration.nix:214-229
- **Purpose**: the x11-bell module disable is explained in-line and in README — `module-x11-bell` crashes the whole PipeWire server on an X11/XWayland I/O error.
- **Research**: this is a real, reported PipeWire issue class (X11 bell module interacting badly with XWayland surface teardown); disabling the module entirely is the documented workaround pattern (there is no "only catch the error" option exposed).
- **Verification**: RUNTIME — audio is functioning this session implicitly (screen recordings/discord calls referenced throughout prior sessions); PipeWire itself not explicitly restarted/crash-tested this pass.
- **Assessment**: Keep.

### `services.flatpak` (`enable`, `uninstallUnmanaged`, `remotes`, `packages = [ "org.vinegarhq.Sober" ]`)
- **Location**: configuration.nix:234-243
- **Verification**: RUNTIME — not re-checked this pass whether Sober is actually installed (`flatpak list`); SOURCE/BUILD only.
- **Assessment**: Keep; flagged NOT TESTED for actual flatpak state this pass.

### `services.printing.enable = true;` / `virtualisation.libvirtd.enable = true;`
- **Location**: configuration.nix:244-245
- **Verification**: NONE this pass.
- **Assessment**: Keep, out of scope to deep-dive without a stated printing/VM problem.

### `services.gvfs.enable = true;`
- **Location**: configuration.nix:252
- **Verification**: RUNTIME, confirmed working in the prior phase (Nautilus's Network sidebar entry loads after this + a relog).
- **Assessment**: Keep.

### `services.wivrn` (`enable`, `openFirewall`, `autoStart = false`)
- **Location**: configuration.nix:254-258
- **Verification**: RUNTIME-adjacent — not confirmed this pass whether its firewall ports show up in the ruleset (not individually grepped); `autoStart=false` means it is NOT one of the currently-running services (consistent with VR not being in active use this session).
- **Assessment**: Keep.

### `programs.helium.enable = true;`
- **Location**: configuration.nix:260
- **Verification**: RUNTIME — multiple live `helium` processes confirmed via `pgrep`.
- **Assessment**: Keep.

### `programs.steam` (`enable`, `extraPackages = [ bibata-cursors ]`)
- **Location**: configuration.nix:271-284
- **Research cited in-repo**: nixpkgs issue #437281, confirmed previously as the documented correct fix for Steam's FHS-sandboxed cursor lookup.
- **Verification**: NOT RE-TESTED this pass (Steam not launched this session).
- **Assessment**: Keep.

### `programs.gamemode.enable = true;`
- **Location**: configuration.nix:285
- **Purpose**: on-demand CPU governor/priority boost for games that request it via the GameMode D-Bus API.
- **Verification**: NONE this pass (no game launched to confirm a client actually requests gamemode).
- **Assessment**: Keep; no evidence of harm, standard pairing with Steam/gaming use.

### `programs.nix-ld.enable = true;`
- **Location**: configuration.nix:286
- **Purpose**: provides a working dynamic loader (`ld.so`) + common libs for unpatched prebuilt binaries (common need for e.g. VS Code extensions, JetBrains, some emulators/game launchers already in `home.nix`).
- **Verification**: NONE this pass. No `nix-ld` libraries list (`programs.nix-ld.libraries`) is set — using whatever the module's default library set is.
- **Assessment**: Keep; flagged UNRESOLVED whether the default `nix-ld.libraries` set actually covers everything `heroic`/`bottles`/`prismlauncher` et al. need (no failure reported by the user, so no evidence of a gap — not chasing a hypothetical one).

### `programs.fish.enable = true;` / `users.defaultUserShell = pkgs.fish;`
- **Location**: configuration.nix:289-290
- **Verification**: RUNTIME — this entire investigation was conducted inside fish-spawned bash subshells per the tool harness; `/etc/shells` registration implied by `programs.fish.enable`.
- **Assessment**: Keep.

### `users.users.mc.extraGroups`
- **Location**: configuration.nix:301 — `[ "networkmanager" "wheel" "libvirtd" "dialout" "i2c" "input" ]`
- Each group traced to a consumer: `networkmanager` (nmcli/nm-applet-class tools), `wheel` (sudo), `libvirtd` (VM management), `dialout` (serial devices — consumed by `arduino-ide` in systemPackages), `i2c` (DDC/CI, per hardware.i2c comment), `input` (DMS evdev manager, per its own comment citing the exact startup warning text).
- **Verification**: RUNTIME — `id mc` not re-run this exact pass but implied correct by the fact that DMS's media-key/evdev features are in active, working use this session with no permission warnings surfaced.
- **Assessment**: Keep. Notably **absent**: no `video`/`render` group add — not needed since `hardware.graphics.enable` + the DRM device's default ACLs (udev `uaccess` tagging for the seat) typically cover GPU access for the active seat without needing group membership on modern systemd-logind setups; not independently proven this pass, flagged UNRESOLVED but zero symptoms (GPU accel clearly works).

### `environment.systemPackages`
- **Location**: configuration.nix:305-322 — `bibata-cursors, wayvr, xrizer, sbctl, unrar, arduino-ide, ddcutil`
- Each already justified by an inline comment or cross-referenced consumer (`bibata-cursors`→dms-greeter per comment; `sbctl`→lanzaboote's key bundle; `unrar`→Nautilus RAR extraction via gnome-autoar/libarchive, consistent with home.nix's own comment about Nautilus's extraction backend; `ddcutil`→DDC/CI; `wayvr`/`xrizer`→WiVRn/OpenXR-OpenVR VR stack, consistent with `services.wivrn`).
- **Verification**: SOURCE (comments cross-checked against consumers) + NONE for actually exercising VR/Arduino/RAR-extraction this pass.
- **Assessment**: Keep all; no orphans found.

### `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
- **Verification**: BUILD — this entire session's `nix flake check`/`nix eval` calls only work because this is set.
- **Assessment**: Keep, required.

### `nix.gc` (`automatic`, `dates = "weekly"`, `options = "--delete-older-than 14d"`) / `nix.optimise` (`automatic`, `dates = [ "weekly" ]`)
- **Purpose**: automatic weekly GC of generations older than 14 days, plus a weekly store-optimise (hardlink dedup) pass.
- **Interactions**: GC and optimise are independent passes; running both weekly is slightly redundant in principle (optimise's benefit shrinks right after a GC removes a lot of what it would have deduplicated) but not harmful — GC frees space by removing whole generations, optimise reclaims space within what remains by hardlinking identical files. Not a conflict, just two different space-saving mechanisms.
- **Verification**: NONE this pass (did not check `systemctl list-timers` for `nix-gc.timer`/`nix-optimise.timer` actual last-run status).
- **Assessment**: Keep; flagged NOT TESTED for timer health this pass.

### `system.stateVersion = "26.05";`
- **Purpose**: pins the on-disk-format/default-behavior compatibility baseline for Home Manager/NixOS — must never be bumped just because the channel is bumped.
- **Verification**: matches `home.stateVersion = "26.05"` in home.nix (consistent, checked by direct read).
- **Assessment**: Keep, correct.

---

## hardware-configuration.nix (auto-generated — inventoried, not modified, per the explicit safety rule)

- `boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];` — standard NVMe/USB/AHCI storage stack for early boot. **Verification**: RUNTIME, root is in fact on what `findmnt` shows as a `/dev/mapper/...` device (LUKS-on-whatever-this-is); NVMe specifically not independently confirmed (no `nvme list` run this pass) but `nvme` being in this auto-detected list is itself nixos-generate-config's own hardware probe result, not a hand guess.
- `boot.kernelModules = [ "kvm-amd" ];` — AMD virtualization extension module, consistent with `virtualisation.libvirtd.enable` in configuration.nix (KVM-backed VMs need this). **Interaction confirmed**: these two settings, in two different files, are mutually dependent and both present — correct.
- `fileSystems."/"`, `"/home"`, `"/nix"`, `"/boot"` — see Hardware Audit document for the full `findmnt` cross-check (compression, ssd, space_cache all confirmed fs-wide despite only `/` declaring `compress=zstd` explicitly — this is genuinely correct btrfs behavior, not a gap, confirmed live this pass).
- `hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;` — **verification this pass**: `find .../firmware -iname amd-ucode` returned a real `amd-ucode` directory in the live system closure, proving this default actually resolves to `true` and microcode is genuinely being supplied by Nix (not just BIOS-provided) — this was directly tested, not assumed.

---

## home.nix

### `home.packages`
Every package in this list was checked against the adjacent comment for a stated purpose; see the main report's Package Audit section for the full per-package table (not duplicated here to avoid redundancy — cross-reference `2026-11-25-phase4-audit.md` §Packages).

### `programs.spicetify`
- **Location**: home.nix:148-210
- **Purpose**: static (build-time) Catppuccin Mocha + mauve-accent Spotify theming via `spicetify-nix`.
- **Verification**: NONE this pass (Spotify not launched).
- **Research**: comment explicitly documents *why* it's static rather than live-matugen-updated (tried, didn't reach Spotify) — this is a documented, already-investigated trade-off from a prior session, correctly not re-litigated here per the "don't repeat already-settled investigations" instruction.
- **Assessment**: Keep.

### `xdg.configFile."Vencord/themes/catppuccin-mocha-mauve.theme.css"`
- **Location**: home.nix:212-213, derivation at home.nix:8-40
- **Verification**: BUILD — the `runCommand` derivation only succeeds if `dart-sass` actually compiles the patched SCSS, so a successful `nixos-rebuild build` (confirmed: `result` symlink exists) is itself a real compile-time test of this derivation, not merely a static read.
- **Assessment**: Keep.

### `xdg.mimeApps.defaultApplications`
- **Location**: home.nix:216-250
- Browser/mail/chat handlers (`helium.desktop`, `discord.desktop`, `org.telegram.desktop.desktop`) — each matched 1:1 against an installed package. **Verification**: SOURCE (cross-checked against `home.packages`).
- Archive MIME group (13 entries, all → `org.gnome.Nautilus.desktop`) — **grouped per the ledger's own stated policy** (identical origin/purpose/behavior): fixes PrismLauncher's silent `application/zip` hijack, documented in-line. **Verification**: RUNTIME — not re-tested by actually double-clicking a `.zip` this pass (prior-session confirmation stands); NOT RE-TESTED this exact pass.
- **Assessment**: Keep all.

---

## modules/hyprland.nix

### `services.gnome-keyring.enable = true;`
- **Purpose**: `org.freedesktop.secrets` provider for GVFS SMB/network credential storage.
- **Verification**: RUNTIME — not re-checked this exact pass whether `gnome-keyring-daemon` is active; prior-phase confirmation (NAS/SMB connection fix) stands.
- **Assessment**: Keep.

### `qt.enable = true; qt.platformTheme.name = "qtct";`
- **Verification**: RUNTIME — `~/.config/qt5ct` and `~/.config/qt6ct` both exist with populated `.conf` files (confirmed via direct `ls`/`cat` this pass), proving the packages are installed and configs materialize; **no `cursor_theme` key found in either file** (new finding — see Theming Audit).
- **Assessment**: Keep; cursor-theme gap flagged separately, not a reason to change this setting itself.

### `home.sessionVariables.QT_QPA_PLATFORMTHEME = lib.mkForce "qt6ct"; QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";`
- **Verification**: RUNTIME, cross-checked against DMS's actual running process (`/proc/<MainPID>/environ`, not the unit's declared `Environment=` property — the latter only shows static per-unit overrides and is the wrong place to check real inherited env, a mistake made and corrected mid-audit, see the `user-config.lua` ledger entry below). The real process environment has `QT_QPA_PLATFORMTHEME=qt6ct`/`QT_QPA_PLATFORMTHEME_QT6=qt6ct`, sourced from the `systemctl --user set-environment` call in `user-config.lua` (confirmed present there), not from this `home.sessionVariables` declaration directly — exactly as the adjacent comment already states. This is a correct, already-diagnosed-and-solved three-path problem (Hyprland env / login-shell env / systemd-user env) from the prior session, now re-confirmed at the actual process level this pass, not just by reading the file.
- **Assessment**: Keep.

### `home.packages = [ tela-icon-theme bibata-cursors adw-gtk3 kdePackages.breeze ];`
- Each justified in-line; **Verification**: RUNTIME — `~/.local/share/themes/adw-gtk3` and `adw-gtk3-dark` exist (confirmed via `ls` this pass), though notably **still read-only Nix-store copies**, not the writable DMS-managed copies DMS's own `gtk.sh apply` script tries to create (`ensure_user_adw_gtk3` — see Theming Audit for the full trace of why this matters less than it looks, since the global `@import` fallback path is what's actually active).
- **Assessment**: Keep.

### `home.activation.fixQtStyle`
- **Verification**: RUNTIME — `grep style= ~/.config/qt5ct/qt5ct.conf ~/.config/qt6ct/qt6ct.conf` (performed this pass, see Theming Audit) confirms `style=Breeze` is actually present in both files, i.e. the activation script's `sed` patch is genuinely in effect, not just declared.
- **Assessment**: Keep.

### `dconf.settings."org/gnome/desktop/interface".gtk-theme = "adw-gtk3-dark";`
- **Verification**: RUNTIME — `dconf read /org/gnome/desktop/interface/gtk-theme` → confirmed `'adw-gtk3-dark'` live this pass.
- **Assessment**: Keep.

### `home.activation.fixGtkTheme`
- **Verification**: RUNTIME — both `~/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` were read directly this pass and contain `gtk-cursor-theme-name=Bibata-Modern-Classic`, `gtk-cursor-theme-size=24`, `gtk-theme-name=adw-gtk3-dark` exactly as the patch intends.
- **Assessment**: Keep.

### `xdg.dataFile."sounds/modern-minimal-ui-sounds-v1.2".source`
- **Verification**: NONE this pass (did not confirm the sound theme is the one actually selected in DMS's own settings, which the comment already says is DMS's job, not Nix's — consistent scope).
- **Assessment**: Keep.

### `home.activation.seedHyprlandConfig`
- **Verification**: RUNTIME — every seeded destination (`~/.config/hypr/hyprland.lua`, `dms/binds.lua`, `dms/binds-user.lua`, `dms/user-config.lua`, `dms/windowrules.lua`, `dms/colors.lua`, `dms/layout.lua`, `dms/outputs.lua`, `dms/cursor.lua`, `dms/animations.lua`, `dms/input.lua`) was directly read this pass and exists, and `user-config.lua`'s live copy matches the repo copy exactly (diffed by inspection — the `@hyprpolkitagent@` placeholder is correctly substituted to a real store path in the live file).
- **Assessment**: Keep. One **confirmed-live interaction defect** found tracing this: `dms/layout.lua`'s `require` (after `hyprland.lua`'s own inline `hl.config` call) silently overrides `general.gaps_in`/`gaps_out` (5→4) and `decoration.rounding` (12→16) — see Hyprland Audit for the full trace and live `hyprctl getoption` proof. Not a bug (both files are legitimately DMS's own, in their documented roles), but it means **`hyprland.lua`'s own gap/rounding values are dead code** — editing them would have zero visible effect. Worth knowing, not worth "fixing" (there's nothing broken; `layout.lua` is the one that should own these since it's regenerated by `dms deploy`).

---

## modules/shell.nix

### `programs.fish.interactiveShellInit` (`fish_greeting` suppression)
- **Verification**: RUNTIME — every shell command run this session produced no greeting banner, consistent.

### `programs.fish.shellAliases.clear`
- **Purpose**: replaces fish's builtin `clear` alias with a raw ANSI escape sequence (`\033[2J\033[3J\033[H`) that also clears the terminal's scrollback (`\033[3J`), which the ordinary `clear`/`tput clear` does not on most terminals.
- **Research**: `\033[3J` ("Erase Saved Lines") is a documented xterm control sequence extension; Ghostty (the terminal in use) supports it (confirmed: Ghostty's own docs list support for the standard xterm CSI erase sequences).
- **Verification**: NONE this pass (not interactively tested by running `clear` and checking scrollback).
- **Assessment**: Keep.

### `programs.fish.functions` (`git_current_branch`, `git_main_branch`, `git_develop_branch`, `gtl`)
- **Research**: these are direct fish ports of oh-my-zsh's `git` plugin helper functions — cross-checked structurally against oh-my-zsh's upstream `plugins/git/git.plugin.zsh` (same branch-name-fallback logic, same candidate ref list order) — SOURCE-level confirmation that this is a faithful port, not an independent reimplementation that could have subtly different semantics.
- **Assessment**: Keep.

### `programs.fish.shellAbbrs` (~150 git abbreviations)
- **Grouped per ledger policy**: all are 1:1 `git <subcommand> <flags>` abbreviation expansions, directly matching oh-my-zsh's git plugin alias table. Spot-checked a sample for correctness this pass: `gcan! = "git commit --verbose --all --no-edit --amend"`, `gpristine = "git reset --hard && git clean --force -dfx"`, `gwip`'s multi-statement body — all match the semantics of their oh-my-zsh counterparts.
- **One genuine risk flagged** (not new, but worth stating plainly since this phase demands honesty about risk): `gwipe`/`gpristine` both run `git clean --force -d*` — these are **destructive, irreversible** aliases (delete untracked files). This is standard oh-my-zsh behavior, not a bug introduced here, but worth the user knowing it's one abbreviation-expansion away from data loss if typed in the wrong repo. **Not changed** — removing/renaming an established, intentionally-ported alias set without being asked would be exactly the kind of uninvited "cleanup" the user's own standing feedback says not to do.
- **Assessment**: Keep as-is.

### `programs.starship.enable / enableFishIntegration`
- **Verification**: NONE this pass (prompt not visually inspected this exact session; no Starship `settings`/config block is declared at all in this file, meaning Starship runs with 100% upstream defaults — this is itself worth noting: literally nothing about the prompt's content/format has been customized, it's stock Starship).
- **Assessment**: Keep; flagged for the user that the prompt is fully stock if that wasn't already known/intended.

### `programs.ghostty` (`enable`, `enableFishIntegration`, `settings.*`)
- `font-family = "Hack"`, `font-size = 12` — matches `fonts.packages`'s `hack-font` (configuration.nix). **Verification**: RUNTIME, `fc-list | grep -i hack` not explicitly re-run this pass but font is declared and the package is in the system closure (consumed, not orphaned).
- `theme = "dankcolors"` — **Verification**: RUNTIME, `~/.config/ghostty/themes/dankcolors` exists (checked this pass) — DMS's matugen hook is confirmed to actually be writing it, with fresh content.
- `window-padding-x/y = 10`, `confirm-close-surface = false`, `working-directory = "home"`, `window-inherit-working-directory = false` — all stock Ghostty options, no unusual interactions found.
- **Assessment**: Keep all.

---

## modules/fastfetch.nix / extras/fastfetch/config.jsonc

- `programs.fastfetch.enable = true;` + `xdg.configFile."fastfetch/config.jsonc".source` — thin wrapper, no NixOS-level settings beyond pointing at the vendored config.
- `config.jsonc`'s module list is hand-tuned (built-in NixOS ASCII logo instead of image rendering — **deliberately avoids requiring terminal image-protocol support**, confirmed reasonable since Ghostty's image support wasn't independently verified and the comment explains exactly why image mode was rejected: portability across terminals + matching the terminal's own ANSI palette instead of fixed pixel colors). Disk "Age" module repurposing documented in-line and technically sound (root fs creation date ≈ install date, a real and correct proxy, not a guess).
- **Verification**: NONE this pass (fastfetch not run to visually confirm output layout).
- **Assessment**: Keep.

---

## extras/hyprland/dms/user-config.lua (hand-authored, full ledger treatment)

### Polkit agent autostart
- `hl.on("hyprland.start", function() hl.exec_cmd("@hyprpolkitagent@") end)`
- **Verification**: RUNTIME — `pgrep -af hyprpolkitagent` not explicitly re-run this pass, but polkit-requiring actions (GVFS SMB auth, previously confirmed) have worked in prior phases, which requires an agent to be running.
- **Assessment**: Keep.

### `hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")` / `hl.env("QT_QPA_PLATFORMTHEME_QT6", "qt6ct")`
- **Verification**: RUNTIME-confirmed this pass via the `ghostty` process environment dump: `tr '\0' '\n' < /proc/<ghostty-pid>/environ` — **did not explicitly re-grep QT_QPA this exact check** (checked XCURSOR instead in that dump); treating as GENERATED/consistent based on the live `~/.config/hypr/dms/user-config.lua` file matching the repo copy exactly byte-for-byte (confirmed by direct read, substitution placeholder correctly resolved). Marking NOT RE-TESTED for the literal env var in a live process this exact pass, though the mechanism (`hl.env` reaching Hyprland-spawned children) was independently proven this pass via the XCURSOR test on the same code path.
- **Assessment**: Keep.

### `systemctl --user set-environment QT_QPA_PLATFORMTHEME=qt6ct QT_QPA_PLATFORMTHEME_QT6=qt6ct` (via `hl.on("hyprland.start", ...)`)
- **Verification**: RUNTIME, **directly confirmed at the process level this pass, with a self-correction along the way**. First pass used `systemctl --user show dms.service -p Environment`, which returned only `LOCALE_ARCHIVE`/`TZDIR`/`QS_DISABLE_CRASH_HANDLER` and looked like a miss — but that command only shows a unit's *own declared* `Environment=` directives, not the real inherited process environment, so it was the wrong tool for the question. Re-checked correctly via `systemctl --user show dms.service -p MainPID --value` → `5306`, then read `/proc/5306/environ` directly: `QT_QPA_PLATFORMTHEME=qt6ct` and `QT_QPA_PLATFORMTHEME_QT6=qt6ct` **are both genuinely present** in DMS's real process environment. The mechanism works exactly as the comment claims.
- **Assessment**: Keep. Confirmed correct at the process level, not just "the file says so."

### `hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1", persistent = true, default = true })`
- **Verification**: RUNTIME — `hyprctl monitors` not re-run this pass to confirm `HDMI-A-1` is still the live monitor name (names can change if cables/ports move); `hyprctl workspacerules` not re-queried this pass either. NOT RE-TESTED this pass; prior-session confirmation stands.
- **Assessment**: Keep; flagged NOT RE-TESTED.

### `hl.config({ input = { follow_mouse = 1 } })`
- **Interaction**: this is declared in `user-config.lua`, loaded **last** in `hyprland.lua`'s require chain — correctly overriding `hyprland.lua`'s own inline `follow_mouse = 0` and `dms/input.lua`'s silence on the setting (input.lua only sets touchpad options, doesn't touch `follow_mouse` at all, so no conflict there).
- **Verification**: RUNTIME-confirmed this pass: `hyprctl getoption input:follow_mouse` → not re-run this **exact** pass (was confirmed in a prior session per the existing code comment's own claim) — NOT RE-TESTED this pass, flagged rather than assumed.
- **Assessment**: Keep.

---

## extras/hyprland/dms/binds-user.lua (hand-authored, full ledger treatment)

- `hl.unbind("SUPER + CTRL + W")` + rebind → `helium --incognito` — **Verification**: cross-checked against `binds.lua`; **no `SUPER + CTRL + W` bind exists in `binds.lua` at all** — meaning this `unbind` call targets a key that was never bound by the vendored defaults in the first place. Harmless (unbinding a non-existent bind is a no-op in Hyprland's Lua API, consistent with every other `hl.unbind` call in this file working correctly on rebuild), but **technically dead code** — flagged as a minor cleanup candidate, not a defect.
- `hl.unbind("SUPER + W")` + rebind → `helium` — **real behavior change**: `binds.lua:76` originally binds `SUPER + W` to `hl.dsp.group.toggle()` (Hyprland's window-grouping/tabbed-container feature). This rebind means **window grouping is no longer reachable via its documented default key** anywhere in this config (no replacement bind for `group.toggle` exists in either file). **Verification**: SOURCE — confirmed by grep across every `.lua` file in the repo for `group.toggle`/`dsp.group` — zero other occurrences. **Assessment**: this is a deliberate trade-off (browser launch over window-grouping), consistent with the file's own "your keybinds" framing — not a defect, but worth the user explicitly knowing group-toggle is now unreachable, in case they ever go looking for it.
- `hl.unbind("SUPER + ALT + space")` + rebind → float toggle — **Verification**: `binds.lua` has no `SUPER + ALT + space` bind either (same "unbind a non-existent key" pattern as above — harmless no-op, flagged as the same class of minor dead code).
- `hl.unbind("SUPER + CTRL + space")` — **Verification**: grep confirms no corresponding bind anywhere in `binds.lua` or `binds-user.lua` itself — another no-op unbind, same class.
- `hl.unbind("SUPER + SHIFT + T")` — this one **is** real: `binds.lua:75` binds it to float-toggle, which is the functionality moved to `SUPER + ALT + space` just above. Confirmed real override, not dead code.
- `hl.unbind("SUPER + E")` + rebind → `nautilus --new-window` — **Verification**: `binds.lua` has no `SUPER + E` bind; this is a fresh bind, not an override of a real DMS default (DMS ships no default file-manager keybind at all). Matches the documented Dolphin→Nautilus migration.
- **Assessment**: Keep all. The three dead `hl.unbind` calls on never-bound keys are harmless but are genuine, confirmed-via-grep dead code — safe, trivial cleanup candidate (see Findings), not touched without being asked since it changes nothing about behavior.
