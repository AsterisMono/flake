_: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = false;
      # 'zap': uninstalls all formulae(and related files) not listed here.
      cleanup = "zap";
      upgrade = true;
    };

    masApps = {
      TencentMeeting = 1484048379;
      Wechat = 836500024;
      NeteaseCloudMusic = 944848654;
      QQ = 451108668;
      Lark = 1551632588;
      "WPS Office" = 1443749478;
    };

    taps = [ "xpipe-io/tap" ];

    brews = [
      "gemini-cli"
      "opencode"
    ];

    casks = [
      "firefox"
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
      "stats"
      "typora"
      "tailscale-app"
      "warp"
      "obsidian"
      "telegram-desktop"
      "chatgpt"
      "xpipe"
      "slack"
      "figma"
      "codex"
      "bruno"
      "1password"
      "1password-cli"
      "karabiner-elements"
      "zed"
      "launchcontrol"
      "ghostty"
      "neovide-app"
      "jetbrains-toolbox"
      "latest"
    ];
  };
}
