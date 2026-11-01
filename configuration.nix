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
      ppfeaturemask = "0xffffffff";
    };
  };

  hardware.bluetooth.enable = true;

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
  };

  # ── Services & programs ─────────────────────────────────────────────────
  services.flatpak.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "dialout" ];
  };

  # ── System packages ─────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    wayvr
    xrizer
    sbctl
    unrar
    arduino-ide
    gnome-system-monitor # Ctrl+Shift+Esc (shortcut defined in modules/gnome.nix)

    # GNOME Shell extensions (enabled declaratively in modules/gnome.nix)
    gnomeExtensions.user-themes # loads the Orchis shell theme
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator # system tray (KStatusNotifierItem + legacy tray icons)
    gnomeExtensions.tiling-shell # KDE/Windows-style window snapping zones
    gnomeExtensions.rounded-corners # rounded screen corners
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
