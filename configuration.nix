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

  # Skip GNOME's default terminal (Ghostty is used instead) and GNOME Web.
  environment.gnome.excludePackages = with pkgs; [
    gnome-console
    epiphany
  ];

  # Give the GDM login screen the same monitor layout as the desktop.
  systemd.tmpfiles.rules = [
    "L+ /run/gdm/.config/monitors.xml - - - - ${./extras/monitors.xml}"
  ];

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
    wayvr
    xrizer
    sbctl
    unrar
    arduino-ide
    gnome-system-monitor # Ctrl+Shift+Esc (shortcut defined in modules/gnome.nix)
    ddcutil # used by the brightness-slider extension

    # GNOME Shell extensions (enabled declaratively in modules/gnome.nix)
    gnomeExtensions.user-themes # loads the Orchis shell theme
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator # system tray (KStatusNotifierItem + legacy tray icons)
    gnomeExtensions.tiling-shell # KDE/Windows-style window snapping zones
    gnomeExtensions.rounded-corners # rounded screen corners
    gnomeExtensions.rounded-window-corners-reborn # rounds windows libadwaita doesn't
    gnomeExtensions.notification-timeout # banners time out without waiting for the mouse
    gnomeExtensions.brightness-control-using-ddcutil # brightness sliders for each monitor
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
