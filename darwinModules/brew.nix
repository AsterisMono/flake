_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
      upgrade = true;
    };

    taps = [ "xpipe-io/tap" ];

    brews = [ ];

    # `brew install --cask`
    casks = [
      "visual-studio-code"
      "google-chrome"
      "iterm2"
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
      "warp"
      "obsidian"
      "telegram-desktop"
      "chatgpt"
      "bitwarden"
      "xpipe"
      "slack"
      "neteasemusic"
      "feishu"
      "figma"
    ];
  };
}
