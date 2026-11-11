{ pkgs, lib, helium-flake, ... }:

{
  imports = [
    ./hardware-configuration.nix
    helium-flake.nixosModules.default
  ];

  nixpkgs.config.allowUnfree = true;

  nixpkgs.overlays = [
    helium-flake.overlays.default
    (final: prev: {
      # Blender built with ROCm (AMD GPU) support.
      blender-rocm = prev.symlinkJoin {
        name = "blender-rocm";
        paths = [ prev.pkgsRocm.blender ];
        nativeBuildInputs = [ prev.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/blender --set LD_PRELOAD "${prev.rocmPackages.rocm-comgr}/lib/libamd_comgr.so.3"
        '';
      };

      # 26.05's pinned Vencord (1.15.13) predates Discord's Nov 2026 switch to
      # an rspack-built web client, so Vencord's WebpackPatcher can't find the
      # module shapes it expects and Discord hangs on "Starting...". Bump to
      # the fixed release (already on nixpkgs master, not yet backported to
      # 26.05 - https://github.com/Vendicated/Vencord/issues/4799). Drop this
      # once the 26.05 branch picks up >=1.15.16.
      vencord = prev.vencord.overrideAttrs (old: rec {
        version = "1.15.16";
        src = final.fetchFromGitHub {
          owner = "Vendicated";
          repo = "Vencord";
          tag = "v${version}";
          hash = "sha256-aUJubLJpyLAZWiOezqFxPY6oVPgWVPQpajFqrJvrO9U=";
        };
        patches = [ ];
        postPatch = "";
        pnpmDeps = final.fetchPnpmDeps {
          pname = old.pname;
          inherit src;
          pnpm = final.pnpm_11;
          fetcherVersion = 4;
          hash = "sha256-HS8uZNepvDefjrsG3buVLFCVv7sHvazcwdpcT3EQ/78=";
        };
      });

      # VS Code 1.144.0 (26.05's current pin) moved ripgrep from
      # @vscode/ripgrep (node_modules/.../bin/rg) to @vscode/ripgrep-universal,
      # unpacked at node_modules.asar.unpacked/.../bin/linux-x64/rg. nixpkgs'
      # vscode derivation still swaps in its own ripgrep at the old path, so the
      # build fails outright (`rm: cannot remove ... No such file or directory`).
      # Point the swap at the real path until nixpkgs' derivation catches up.
      vscode = prev.vscode.overrideAttrs (old: {
        postPatch = builtins.replaceStrings
          [ "resources/app/node_modules/@vscode/ripgrep/bin/rg" ]
          [ "resources/app/node_modules.asar.unpacked/@vscode/ripgrep-universal/bin/linux-x64/rg" ]
          old.postPatch;
      });
    })
  ];

  # ── Boot ────────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [ "quiet" "splash" ];
  boot.kernel.sysctl."vm.swappiness" = 100;

  boot.plymouth = {
    enable = true;
    theme = "spinner";
  };

  # The systemd initrd is required for TPM2 unlocking of the LUKS volume.
  boot.initrd.systemd.enable = true;
  boot.initrd.luks.devices."luks-bf6cf5c5-2572-48ec-ac11-70b12ae93142".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];

  boot.loader.timeout = 0;
  boot.loader.efi.canTouchEfiVariables = true;
  # Lanzaboote (Secure Boot) replaces systemd-boot's own enable.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    memoryMax = 8 * 1024 * 1024 * 1024; # 8 GiB
  };

  # ── Hardware ────────────────────────────────────────────────────────────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu = {
    opencl.enable = true;
    overdrive = {
      enable = true;
      # 0xffffffff (the module's default, needed for LACT overclocking) with bit 0x8000
      # (PP_GFXOFF_MASK) cleared, forcing GFXOFF off. Added after repeated
      # "Failed to disable gfxoff!" spam in dmesg from this RX 6600 XT, which stopped
      # appearing in the journal entirely once this landed - keep until nixpkgs/amdgpu
      # ships a real fix for whatever SMU race causes the driver's own GFXOFF-disable
      # request to fail in the first place.
      ppfeaturemask = "0xffff7fff";
    };
  };

  hardware.bluetooth.enable = true;

  # DDC/CI access for the monitor brightness sliders (loads i2c-dev, adds the udev rule).
  hardware.i2c.enable = true;

  services.lact.enable = true;
  systemd.services.lactd.path = [ "/run/wrappers" ];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "amd";
  };

  # ── Networking ──────────────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # KDE Connect protocol, GNOME front-end (GSConnect). Opens the needed
  # firewall ports; the extension itself is enabled in modules/gnome.nix.
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  # ── Locale ──────────────────────────────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Desktop (GNOME) ─────────────────────────────────────────────────────
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # RDP server for GNOME's built-in "Remote Desktop" screen sharing.
  services.gnome.gnome-remote-desktop.enable = true;
  networking.firewall.allowedTCPPorts = [ 3389 ];

  # services.gnome.gnome-remote-desktop only links the system-level
  # gnome-remote-desktop{,-configuration}.service unit files in (systemd
  # reports them as "linked", not "enabled"/"disabled") without wiring them
  # into any target. gnome-control-center's System panel hides its entire
  # "Remote Desktop" row unless that *system*-scope service reports
  # "enabled" or "disabled" (see cc_get_service_state() in
  # panels/system/cc-system-panel.c) — "linked" reads as "not found", so the
  # row — and with it the actual on/off switch — never appears in Settings.
  # The row itself still toggles the per-session (--user) RDP daemon we
  # already have running; this only makes systemd recognize the system unit
  # as properly installed so the panel stops hiding it.
  systemd.services.gnome-remote-desktop.wantedBy = [ "graphical.target" ];
  systemd.services.gnome-remote-desktop-configuration.wantedBy = [ "graphical.target" ];

  # Skip GNOME's default terminal (Ghostty is used instead) and GNOME Web.
  environment.gnome.excludePackages = with pkgs; [
    gnome-console
    epiphany
  ];

  # Give the GDM login screen the same monitor layout as the desktop.
  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${./extras/monitors.xml}"
  ];

  # Match GDM's login screen to the Orchis theme (gtk/icon theme, purple accent,
  # Bibata cursor) so it fits with the rest of modules/gnome.nix.
  # The gdm user has no home-manager profile of its own, so this is set directly
  # on its dconf database rather than via `dconf.settings` like the rest of GNOME.
  services.displayManager.gdm.extraPackages = with pkgs; [ orchis-theme tela-icon-theme bibata-cursors ];

  # The cursor-theme setting above only tells mutter *which* theme to load; it
  # still has to find it. libXcursor's theme search path is hardcoded to
  # ~/.icons, ~/.local/share/icons and /usr/share/icons — it never looks at
  # XDG_DATA_DIRS, so putting bibata-cursors in extraPackages above doesn't
  # help. In a normal session home-manager symlinks the theme into ~/.icons,
  # but the gdm-greeter user has no home directory contents at all, so mutter
  # can't locate Bibata there and falls back to a blank/white box cursor.
  # Linking it into the system profile instead puts it on XCURSOR_PATH for
  # every session (NixOS already adds /run/current-system/sw/share/icons to
  # XCURSOR_PATH — see <nixpkgs/nixos/modules/config/xdg/icons.nix>; the
  # package itself is added to environment.systemPackages below).
  programs.dconf.profiles.gdm.databases = [{
    settings."org/gnome/desktop/interface" = {
      accent-color = "purple";
      color-scheme = "prefer-dark";
      cursor-theme = "Bibata-Modern-Classic";
      gtk-theme = "Orchis-Purple-Dark"; # must match `orchisTheme` in home.nix
      icon-theme = "Tela-purple-dark";
    };
  }];

  fonts.packages = with pkgs; [
    hack-font # monospace font (Ghostty + GNOME)
    noto-fonts # "Noto Sans", the interface/document font set in GNOME
  ];

  # The generic families (what apps get when they ask for "sans-serif",
  # "serif" or "monospace"). Plasma used to set these; GNOME doesn't.
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
    monospace = [ "Hack" "Noto Sans Mono" ];
  };

  # Makes system fonts visible to Flatpak apps.
  fonts.fontDir.enable = true;

  # ── Audio ───────────────────────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # module-x11-bell (redirects the old X11 system bell through libcanberra)
    # crashes the whole PipeWire server on an X11/XWayland I/O error, taking
    # every audio client down with it (including GNOME's own sound daemon,
    # which doesn't reconnect, silently killing event sounds for the rest of
    # the session). It's only the legacy bell beep, so just disable it.
    extraConfig.pipewire."10-disable-x11-bell" = {
      "context.properties" = {
        "module.x11.bell" = false;
      };
    };
  };

  # modules/gnome.nix's shutdown-sound-grace-period holds a logind shutdown
  # inhibitor so the 2.9s logout sound isn't cut off by poweroff/reboot.
  # Default (5s) leaves only ~2.1s of headroom once session-teardown signal
  # propagation eats into it; bumped by 1s of slack, not padded further.
  services.logind.settings.Login.InhibitDelayMaxSec = 6;

  # Like desktop-login/-logout (see modules/gnome.nix), GNOME dropped native
  # device-added/device-removed sounds years ago; nothing in gnome-settings-daemon
  # or gnome-shell plays them anymore. Recreate it with a udev rule (fires once per
  # physical USB device, not per interface) that starts a templated system service
  # playing the sound as the desktop user.
  #
  # Unlike login-logout-sound (a `systemd --user` unit, which inherits the full
  # graphical session environment), this is a plain `systemd.services` unit started
  # by PID1 — it never sees XDG_DATA_DIRS, DBUS_SESSION_BUS_ADDRESS, DISPLAY, etc.
  # `canberra-gtk-play --id=` needs exactly that session environment to resolve the
  # configured sound theme via GTK/GSettings, so under this service it always failed
  # silently ("File or data not found") even though the sound files are right there.
  # Pointing `--file=` straight at this theme's .oga sidesteps theme resolution
  # entirely, so it only needs PipeWire (via XDG_RUNTIME_DIR) to actually play.
  systemd.services."usb-sound@" = {
    description = "Play a sound on USB device %i";
    serviceConfig = {
      Type = "oneshot";
      User = "mc";
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      ExecStart = "${pkgs.libcanberra-gtk3}/bin/canberra-gtk-play --file=${./extras/sounds/modern-minimal-ui-sounds-v1.2/stereo}/device-%i.oga";
    };
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", TAG+="systemd", ENV{SYSTEMD_WANTS}+="usb-sound@added.service"
    # SYSTEMD_WANTS only fires when a device unit *becomes active* (systemd.device(5)) —
    # it's never acted on for "remove", since the device unit is going inactive, not
    # active. Start the service straight from the udev worker instead; --no-block keeps
    # the rule itself fast since it only queues the job rather than waiting on it.
    ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", RUN+="${pkgs.systemd}/bin/systemctl --no-block start usb-sound@removed.service"
  '';

  # ── Services & programs ─────────────────────────────────────────────────
  # Declarative flatpaks (nix-flatpak): apps installed/removed to match this
  # list on every rebuild, so nothing lingers from a manual `flatpak install`.
  services.flatpak = {
    enable = true;
    uninstallUnmanaged = true;
    remotes = [
      { name = "flathub"; location = "https://flathub.org/repo/flathub.flatpakrepo"; }
    ];
    packages = [
      "org.vinegarhq.Sober" # Roblox client
    ];

    # Sandboxed apps otherwise can't see the host theme/icon files, and GTK3
    # ignores GNOME's theme entirely unless told to via GTK_THEME. GTK4/
    # libadwaita apps still won't pick up Orchis itself (GTK4 removed support
    # for theme engines; they only follow accent colour + light/dark via the
    # portal), but this covers every GTK3 app and the icon set for both.
    overrides.settings.global = {
      Context.filesystems = [ "xdg-data/themes:ro" "xdg-data/icons:ro" ];
      Environment = {
        GTK_THEME = "Orchis-Purple-Dark"; # must match `orchisTheme` in home.nix
        # Non-GTK (X11/XWayland, libXcursor) apps don't read GTK's cursor
        # setting; this is what they actually consult.
        XCURSOR_THEME = "Bibata-Modern-Classic";
        XCURSOR_SIZE = "24";
      };
    };
  };
  services.printing.enable = true;
  virtualisation.libvirtd.enable = true;

  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = false;
  };

  programs.helium.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.nix-ld.enable = true;

  # fish is the login shell (programs.fish.enable also registers it in /etc/shells).
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # ── User ────────────────────────────────────────────────────────────────
  users.users.mc = {
    isNormalUser = true;
    description = "mc";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "dialout" "i2c" ];
  };

  # ── System packages ─────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    bibata-cursors # on XCURSOR_PATH for every session, incl. the GDM greeter — see note above gdm.extraPackages
    wayvr
    xrizer
    sbctl
    unrar
    arduino-ide
    gnome-system-monitor # Ctrl+Shift+Esc (shortcut defined in modules/gnome.nix)
    ddcutil # used by the brightness-slider extension
    openssl # gnome-control-center shells out to this to generate the Remote Desktop TLS cert

    # GNOME Shell extensions (enabled declaratively in modules/gnome.nix)
    gnomeExtensions.user-themes # loads the Orchis shell theme
    # nixpkgs ships v72, which has no blur for popup menus/calendar/quick settings
    # (that landed in v73) and has a since-fixed panel blur bug (upstream v77
    # changelog). Pinned to v77 until nixpkgs catches up.
    (gnomeExtensions.blur-my-shell.override {
      version = 77;
      sha256 = "sha256-Kxscapq5bqZypfhq7l70cglDcqMu4JbzU9krVonG/bw=";
      metadata = "ewogICJfZ2VuZXJhdGVkIjogIkdlbmVyYXRlZCBieSBTd2VldFRvb3RoLCBkbyBub3QgZWRpdCIsCiAgImRlc2NyaXB0aW9uIjogIkFkZHMgYSBibHVyIGxvb2sgdG8gZGlmZmVyZW50IHBhcnRzIG9mIEdOT01FIFNoZWxsLCBpbmNsdWRpbmcgdGhlIHRvcCBwYW5lbCwgZGFzaCBhbmQgb3ZlcnZpZXcuXG5cbk5vdGU6IGlmIHRoZSBleHRlbnNpb24gc2hvd3MgYW4gZXJyb3IgYWZ0ZXIgdXBkYXRpbmcsIHJlc3RhcnQgeW91ciBzZXNzaW9uIHRvIHNlZSB3aGV0aGVyIGl0IHBlcnNpc3RzLiBUaGlzIGlzIGR1ZSB0byBhIEdOT01FIFNoZWxsIGJ1ZyB0aGF0IHRoZSBleHRlbnNpb24gY2Fubm90IHdvcmsgYXJvdW5kLiIsCiAgImRvbmF0aW9ucyI6IHsKICAgICJnaXRodWIiOiAiYXVuZXR4IiwKICAgICJrb2ZpIjogImF1bmV0eCIKICB9LAogICJnZXR0ZXh0LWRvbWFpbiI6ICJibHVyLW15LXNoZWxsQGF1bmV0eCIsCiAgIm5hbWUiOiAiQmx1ciBteSBTaGVsbCIsCiAgIm9yaWdpbmFsLWF1dGhvcnMiOiBbCiAgICAibWVAYXVuZXR4LmRldiIKICBdLAogICJzZXNzaW9uLW1vZGVzIjogWwogICAgInVubG9jay1kaWFsb2ciLAogICAgInVzZXIiCiAgXSwKICAic2V0dGluZ3Mtc2NoZW1hIjogIm9yZy5nbm9tZS5zaGVsbC5leHRlbnNpb25zLmJsdXItbXktc2hlbGwiLAogICJzaGVsbC12ZXJzaW9uIjogWwogICAgIjQ2IiwKICAgICI0NyIsCiAgICAiNDgiLAogICAgIjQ5IiwKICAgICI1MCIsCiAgICAiNTEiCiAgXSwKICAidXJsIjogImh0dHBzOi8vZ2l0aHViLmNvbS9hdW5ldHgvYmx1ci1teS1zaGVsbCIsCiAgInV1aWQiOiAiYmx1ci1teS1zaGVsbEBhdW5ldHgiLAogICJ2ZXJzaW9uIjogNzcKfQ==";
    })
    gnomeExtensions.dash-to-dock
    # Patched: force-menu-location (BottomCentered here, see modules/gnome.nix)
    # always positions the menu using the monitor ArcMenu's own button lives on
    # (this._monitorIndex, fixed to the primary monitor - ArcMenu only creates
    # a second real button/menuController per monitor when Dash to Panel is
    # driving it, which isn't the case here), ignoring where the mouse actually
    # is. Invisible with one monitor, but means both the Super-key hotkey and
    # clicking the copy multi-monitor-bar clones onto the second monitor above
    # always pop the menu up on the primary monitor instead of wherever the
    # mouse is. forceMenuLocation() recomputes the menu's position fresh every
    # time it opens, so reading Main.layoutManager.currentMonitor (GNOME's own
    # "monitor the pointer is over right now") instead of the fixed index/actor
    # makes it follow the mouse on every open, Super-key or click alike.
    (gnomeExtensions.arcmenu.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        sed -i -E -z \
          -e 's/const monitor = Main\.layoutManager\.findMonitorForActor\(this\);\n(\s*)const workArea = Main\.layoutManager\.getWorkAreaForMonitor\(this\._monitorIndex\);/const monitor = Main.layoutManager.currentMonitor ?? Main.layoutManager.findMonitorForActor(this);\n\1const workArea = Main.layoutManager.getWorkAreaForMonitor(monitor?.index ?? this._monitorIndex);/' \
          $out/share/gnome-shell/extensions/*/menuButton.js
      '';
    })) # traditional application-menu launcher button
    # GNOME's own top bar only ever draws on the primary monitor - there is no
    # vanilla setting for this. This clones a top bar (clock, Activities/ArcMenu
    # button, quick settings, etc.) onto every other monitor instead.
    gnomeExtensions.multi-monitor-bar
    gnomeExtensions.appindicator # system tray (KStatusNotifierItem + legacy tray icons)
    gnomeExtensions.tiling-shell # KDE/Windows-style window snapping zones
    gnomeExtensions.rounded-corners # rounded screen corners
    gnomeExtensions.rounded-window-corners-reborn # rounds windows libadwaita doesn't
    gnomeExtensions.notification-timeout # banners time out without waiting for the mouse
    gnomeExtensions.brightness-control-using-ddcutil # brightness sliders for each monitor
    gnomeExtensions.caffeine # "stay awake" coffee-cup toggle in the quick settings menu
    # Windows/KDE-style clipboard history (Super+V, see modules/gnome.nix).
    # Not Pano: Pano has no real GNOME 50 support yet (upstream fix is an
    # unmerged PR - https://github.com/oae/gnome-shell-pano/pull/381 - and
    # there's an open report of it freezing the shell on GNOME 49/50).
    gnomeExtensions.clipboard-history
    gnomeExtensions.emoji-copy # emoji picker popup (Super+., default keybind out of the box)
    # KDE-style panel widget showing/controlling the current MPRIS player.
    # Patched: nixpkgs' build only declares shell-version support up to 49;
    # GNOME 50 isn't out yet upstream. The extension itself works fine on 50,
    # it just hasn't been re-tagged, so this adds "50" to metadata.json.
    (gnomeExtensions.media-controls.overrideAttrs (old: {
      postInstall = (old.postInstall or "") + ''
        sed -i 's/"49"/"49", "50"/' $out/share/gnome-shell/extensions/*/metadata.json
      '';
    }))
  ];

  # ── Nix ─────────────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  system.stateVersion = "26.05";
}
