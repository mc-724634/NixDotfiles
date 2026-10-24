{ config, pkgs, ... }:

{
  programs.fastfetch = {
    enable = true;
  };

  home.file.".config/fastfetch/config.jsonc".source =
    ../extras/fastfetch/config.jsonc;

  home.file.".config/fastfetch/logo/catppuccin_logo.png".source =
    ../extras/fastfetch/catppuccin_logo.png;
}
