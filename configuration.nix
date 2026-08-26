# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, helium-flake, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      helium-flake.nixosModules.default
    ];

  nixpkgs.overlays = [
    helium-flake.overlays.default
  ];

  system.activationScripts.sbctlSignBoot.text = ''
    ${pkgs.sbctl}/bin/sbctl sign-all
  '';

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    "amdgpu.ppfeaturemask=0xffffffff"
    "quiet"
    "splash"
  ];

  boot.initrd.systemd.enable = true;

  boot.initrd.luks.devices."luks-bf6cf5c5-2572-48ec-ac11-70b12ae93142".crypttabExtraOpts = [
    "tpm2-device=auto"
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  networking.firewall = {
    enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # Note: extraLocaleSettings removed — every LC_* category was being set to the
  # exact same value as defaultLocale, which is what those categories already
  # inherit by default. Pure redundancy, no behavior change from removing it.

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    memoryMax = 8 * 1024 * 1024 * 1024; # 8 GiB
  };

  # zram is compressed RAM, not disk — it's fast enough that the kernel should
  # be encouraged to use it, not avoid it. 15 was tuned for disk-swap avoidance;
  # kernel docs recommend well above the 60 default (100+) once swap is in-memory.
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.flatpak.enable = true;

  # Helium Browser Conf
  programs.helium = {
    enable = true;
  };

  programs.steam = {
    enable = true;
  };

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
   konsole
  ];

  programs.gamemode.enable = true;

  services.lact.enable = true;

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

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins; # optional, gets you extra device plugins
    motherboard = "amd"; # or "intel", if you want motherboard RGB support via i2c
  };

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.plasma-login-manager.enable = true;

  services.displayManager.plasma-login-manager.settings = {
    "Greeter/Wallpaper/org.kde.image/General" = {
      Image = "file://${./extras/kde/wallpapers/cat-vibin.png}";
    };
  };

  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."mc" = {
    isNormalUser = true;
    description = "mc";
    extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
  };

  # Install firefox.
  programs.firefox.enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    zsh
    kdePackages.partitionmanager
    gnome-boxes
    wayvr
    xrizer
    sbctl
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Swapped auto-optimise-store for a scheduled optimise pass: the old setting
  # ran store optimisation (hardlinking) after every single build, which adds
  # real overhead when building large packages (blender, godot, steam, etc.).
  # This gets you the same disk savings on a weekly cadence instead.
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "weekly" ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}
