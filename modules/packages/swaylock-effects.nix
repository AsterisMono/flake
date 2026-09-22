_: {
  perSystem =
    { pkgs, ... }:
    {
      packages.swaylock-effects = pkgs.swaylock-effects.overrideAttrs (old: {
        # Scale clock typography with the output and align both lines to the
        # left edge of the indicator; authentication messages keep their size.
        patches = (old.patches or [ ]) ++ [ ./swaylock-effects-clock.patch ];
      });
    };
}
