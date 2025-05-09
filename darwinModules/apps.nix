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
      "tailscale"
      "firefox"
      "warp"
      "obsidian"
      "telegram-desktop"
      "chatgpt"
    ];
  };
}
