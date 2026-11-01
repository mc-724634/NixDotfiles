{ ... }:

{
  programs.fastfetch.enable = true;

  xdg.configFile."fastfetch/config.jsonc".source = ../extras/fastfetch/config.jsonc;
}
