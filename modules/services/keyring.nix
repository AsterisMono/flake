_: {
  # Provides the Secret Service D-Bus API. Zed-based editors (including Delta)
  # store account credentials through it, and login auto-unlock comes from
  # `login`'s PAM rules, which greetd's session includes.
  flake.modules.nixos.keyring = {
    services.gnome.gnome-keyring.enable = true;
  };
}
