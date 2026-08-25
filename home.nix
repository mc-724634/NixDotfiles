{ config, pkgs, spicetify-nix, inputs, ... }:
let
  shellAliases = {
    clear = "printf '\\033[2J\\033[3J\\033[H'";
  };
in
{
  imports = [
    spicetify-nix.homeManagerModules.default
    ./modules/kde.nix
    ./modules/fastfetch.nix
  ];
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "mc";
  home.homeDirectory = "/home/mc";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "26.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    git
    wget
    hyfetch
    kdePackages.kcalc
    haruna
    vesktop
    telegram-desktop
    blender
    prismlauncher
    heroic
    godot
    cemu
    dolphin-emu
    retroarch
    steam-rom-manager
    vscodium
    orca-slicer
    klassy
    easyeffects
    krita
    inputs.appgrid.packages.${pkgs.system}.default
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  #home.file.

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/mc/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  programs.spicetify =
    let
      spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;

      theme = spicePkgs.themes.catppuccin;
      colorScheme = "macchiato";

      enabledExtensions = with spicePkgs.extensions; [
        shuffle
        beautifulLyrics
        adblockify
        volumePercentage
        copyLyrics
      ];
    };

  programs.zsh = {
    enable = true;
    shellAliases = shellAliases;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;

    presets = [
      "catppuccin-powerline"
    ];
  
  settings = {
    line_break.disabled = false;
    
  
    os = {
      disabled = false;

      symbols = {
        NixOS = " ";
        };
      };
    };
  };

  programs.kitty = {
    enable = true;
    themeFile = "Catppuccin-Macchiato";
  
    font = {
      name = "Hack";
      size = 12;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
