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
      "typora" # to be packaged (darwin)
    ];
  };
}
