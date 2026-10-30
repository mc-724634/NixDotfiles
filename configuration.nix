{ config, pkgs, lib, helium-flake, nur, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      helium-flake.nixosModules.default
    ];

  nixpkgs.overlays = [
    helium-flake.overlays.default
    nur.overlays.default
    (final: prev: {
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

  boot.plymouth = {
    enable = true;
    theme = "spinner";
  };

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
  programs.zsh.enable = true;

  # Use latest zen kernel.
  boot.kernelPackages = pkgs.linuxPackages_zen;

boot.kernelParams = [
  "quiet"
  "splash"
];

hardware.amdgpu.overdrive = {
  enable = true;
  ppfeaturemask = "0xffffffff";
};
  boot.loader.timeout = 0;

  boot.initrd.systemd.enable = true;

  # Lanzaboote replaces systemd-boot's own enable.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };

  boot.initrd.luks.devices."luks-bf6cf5c5-2572-48ec-ac11-70b12ae93142".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];

  networking.hostName = "nixos";

  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  networking.firewall = {
    enable = true;
  };

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    memoryMax = 8 * 1024 * 1024 * 1024; # 8 GiB
  };

  services.lact.enable = true;
  systemd.services.lactd.path = [ "/run/wrappers" ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu.opencl.enable = true;

  services.flatpak.enable = true;

  programs.helium = {
    enable = true;
  };

  programs.steam = {
    enable = true;
  };

  # Skip GNOME's default terminal (kitty is used instead).
  environment.gnome.excludePackages = with pkgs; [
    gnome-console
  ];

  programs.gamemode.enable = true;

  virtualisation.libvirtd.enable = true;

  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = false;
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  programs.nix-ld.enable = true;

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "amd";
  };

  # KDE Connect protocol, GNOME front-end (GSConnect). Opens the needed
  # firewall ports; the extension is enabled in home.nix.
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
  };

  services.xserver.enable = false;

  services.displayManager.gdm.enable = true;

  services.desktopManager.gnome.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users."mc" = {
    isNormalUser = true;
    description = "mc";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" "dialout" ];
  };

  programs.firefox.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    zsh
    wayvr
    xrizer
    sbctl
    unrar
    arduino-ide
    gnomeExtensions.user-themes # lets GNOME Shell load the Orchis shell theme
    gnomeExtensions.blur-my-shell
    gnomeExtensions.dash-to-dock
    gnomeExtensions.appindicator # system tray (KStatusNotifierItem + legacy tray icons)
    gnomeExtensions.tiling-shell # KDE/Windows-style window snapping zones
  ];

  system.stateVersion = "26.05";

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
