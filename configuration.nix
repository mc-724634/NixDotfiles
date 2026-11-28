{ pkgs, lib, helium-flake, nur, ... }:

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
    })
    (final: prev: {
      # nixpkgs' own kdePackages.qt6ct has no KDE theming support at all
      # (upstream qt6ct, not the qt6ct-kde fork - open, unresolved nixpkgs
      # issue #489021). NUR's ilya-fedin/nur-repository ships the patched
      # build (confirmed: pulls in kcolorscheme/kiconthemes as real deps,
      # drop-in replacement for the plain package - same binary, same
      # plugin layout). Overriding it here means every existing use of
      # kdePackages.qt6ct (home-manager's qt.platformTheme.name = "qtct" in
      # modules/hyprland.nix) picks up the fix automatically, nothing else
      # needs to change.
      kdePackages = prev.kdePackages // {
        qt6ct = nur.legacyPackages.${prev.system}.repos.ilya-fedin.qt6ct;
      };
    })
  ];

  # ── Boot ────────────────────────────────────────────────────────────────
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.kernelParams = [
    "quiet"
    "splash"
    # Stock LACT-required featuremask (GFXOFF left enabled). Previously ran
    # with bit 0x8000 (PP_GFXOFF_MASK) cleared (0xffff7fff) to force GFXOFF
    # off, since this RX 6600 XT's SMU fails to disable it on its own and
    # spams "Failed to disable gfxoff!" in dmesg - reverted back to the
    # default mask at the user's request.
    "amdgpu.ppfeaturemask=0xffffffff"
  ];
  boot.kernel.sysctl."vm.swappiness" = 100;

  boot.plymouth = {
    enable = true;
    # Stock theme: motherboard/OEM logo from the firmware's BGRT table, with
    # the normal spinner overlaid (bundled with plymouth itself, no extra
    # themePackages needed).
    theme = "bgrt";
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
    # Load amdgpu in the initrd (early KMS) so Plymouth's DRM renderer is in
    # control from the start. Without this, Plymouth starts on the generic
    # EFI framebuffer and amdgpu takes over mid-boot, resetting the display
    # and killing the spinner animation (the static BGRT logo survives the
    # handoff, but the throbber's render loop doesn't).
    initrd.enable = true;
    opencl.enable = true;
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

  # KDE Connect protocol/pairing. DE-agnostic (not Plasma-specific) - opens
  # the needed firewall ports and installs the kdeconnect-kde package itself.
  programs.kdeconnect.enable = true;

  # ── Locale ──────────────────────────────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Desktop (Hyprland + Dux Shell) ───────────────────────────────────────
  # Migrated off KDE Plasma (2026-11-22) - KDE is gone for good, not kept
  # around for a revert.
  #
  # Login screen is DMS's own dms-greeter (greetd-backed), not SDDM - it
  # renders in the same Hyprland compositor the rest of the session uses and
  # picks up the logged-in user's DMS wallpaper/colors, instead of a generic
  # greeter theme that has nothing to do with the rest of this setup.
  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/mc";
  };
  programs.hyprland.enable = true;
  # Hyprland's own packaged session launcher (start-hyprland) invokes UWSM
  # unconditionally now, regardless of this flag - but leaving it at the
  # module's default (false) means NixOS never wires UWSM's systemd user
  # units into the session's unit search path, so the launcher's own
  # internal "systemctl --user start wayland-session-bindpid@<pid>.service"
  # call fails with "unit not found" and the whole session tears down ~10s
  # after login. Matching this to true is what actually makes the package's
  # own launcher behavior work.
  programs.hyprland.withUWSM = true;

  programs.dank-material-shell = {
    enable = true;
    # Clipboard and brightness control are built into DMS now (no toggle
    # needed - the module rejects enableClipboard/enableBrightnessControl as
    # dead options). This just backs Super+M (process list).
    enableClipboardPaste = true;
    enableSystemMonitoring = true;
    # DMS's own systemd user service (Type=notify, Restart=on-failure,
    # ordered before tray.target) instead of the bare exec Hyprland's own
    # generated startup block used to do. Gets auto-restart-on-crash and
    # auto-restart-on-package-update for free, and tray icon apps no longer
    # risk starting before DMS's tray host is actually ready. The matching
    # exec hook was removed from extras/hyprland/hyprland.lua - leaving both
    # active would race two processes for the same D-Bus name
    # (org.freedesktop.Notifications) and one would lose.
    systemd.enable = true;
  };

  fonts.packages = with pkgs; [
    hack-font # monospace font (Ghostty)
    noto-fonts
  ];

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
    # every other audio client in the session down with it too. It's only
    # the legacy bell beep, so just disable it.
    extraConfig.pipewire."10-disable-x11-bell" = {
      "context.properties" = {
        "module.x11.bell" = false;
      };
    };
  };

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
  };
  services.printing.enable = true;
  virtualisation.libvirtd.enable = true;

  # GVFS - never installed at all on this system (nothing needed it before
  # switching to Nautilus). Without it, `gio list network:///` returns
  # "Operation not supported" - confirmed live - and Nautilus's "Network"
  # sidebar entry can't load anything. Provides gvfsd itself plus the
  # network/dnssd/smb/trash backends GTK/GNOME apps expect to just exist.
  services.gvfs.enable = true;

  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = false;
  };

  programs.helium.enable = true;
  # ExtensionInstallForcelist (tried for the Catppuccin Mocha Chrome theme)
  # doesn't actually work here: chrome://policy reports it as accepted, but
  # the extension never appears in the profile's extensions.settings and
  # never installs - confirmed by inspecting Preferences directly, not just
  # a timing issue. Likely deliberate: Helium's whole premise is resisting
  # exactly this kind of silent policy-forced install (the same mechanism
  # browser hijackers/corporate spyware abuse), so it validates the policy
  # schema but doesn't act on it. Install Chrome Web Store items by hand
  # instead (visit the store page in Helium, click install) - not something
  # to fight further here.
  programs.steam = {
    enable = true;
    # Steam's client UI runs inside its own FHS-compliant sandbox (bubblewrap),
    # built only from this package list - NOT from home.packages or
    # environment.systemPackages. That sandbox has its own isolated
    # filesystem image, so Bibata (installed everywhere else on this system)
    # was never actually reachable from inside it: every fix that targeted
    # the real filesystem (GTK settings.ini, XCURSOR_PATH, a shadowed
    # "Adwaita" cursor theme under ~/.local/share/icons) had zero effect
    # because Steam's sandboxed cursor lookup never saw any of it. Confirmed
    # via https://github.com/NixOS/nixpkgs/issues/437281 - this is the
    # documented, correct fix, not a guess.
    extraPackages = [ pkgs.bibata-cursors pkgs.mangohud ];
  };
  programs.gamemode.enable = true;
  programs.nix-ld.enable = true;

  # fish is the login shell (programs.fish.enable also registers it in /etc/shells).
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;

  # ── User ────────────────────────────────────────────────────────────────
  users.users.mc = {
    isNormalUser = true;
    description = "mc";
    # "input" is what DMS's own evdev manager needs for raw input device
    # access - confirmed via its own startup warning ("Failed to initialize
    # evdev manager: insufficient permissions... Add your user to the
    # 'input' group"), logged on every single startup in the journal
    # (`journalctl --user -u dms`) without it.
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "dialout" "i2c" "input" ];
  };

  # ── System packages ─────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    # dms-greeter's own cursor-sync logic (core/internal/launcher/cursor.go
    # in the dux-greeter source) reads cursorSettings.theme out of the
    # user's synced settings.json and sets XCURSOR_THEME/XCURSOR_PATH for
    # the login screen automatically - but only if it can find that theme
    # under one of its search dirs, which always includes
    # /run/current-system/sw/share/icons (this list). bibata-cursors is
    # already in modules/hyprland.nix's home.packages for the user session,
    # but that only reaches the user's own profile, never the system one
    # the greeter (running as a separate "greeter" user) can see.
    bibata-cursors
    wayvr
    xrizer
    sbctl
    unrar
    arduino-ide
    ddcutil # DDC/CI monitor brightness control
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
