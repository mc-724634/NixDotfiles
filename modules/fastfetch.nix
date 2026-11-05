{ ... }:

{
  programs.fastfetch.enable = true;

  xdg.configFile = {
    "fastfetch/config.jsonc".source = ../extras/fastfetch/config.jsonc;
    "fastfetch/nixos-logo.png".source = ../extras/fastfetch/nixos-logo.png;
  };
}
