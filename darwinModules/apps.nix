{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
  ];

  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
      upgrade = true;
    };

    taps = [ ];

    brews = [ ];

    # `brew install --cask`
    casks = [
      "visual-studio-code"
      "cursor"
      "google-chrome"
      "iterm2"
      "arc"
      "orbstack"
      "font-fira-code-nerd-font"
      "font-maple-mono-nf-cn"
      "alt-tab"
      "maccy"
      "shottr"
      "raycast"
      "dbeaver-community"
      "rectangle"
      "jordanbaird-ice"
      "onedrive"
      "insomnia"
      "stats"
      "typora"
      "tailscale-app"
      "firefox"
      "warp"
      "obsidian"
      "telegram-desktop"
      "chatgpt"
      "bitwarden"
      "ghostty"
      "marta"
    ];
  };
}
