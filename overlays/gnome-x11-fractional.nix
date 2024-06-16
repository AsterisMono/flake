final: prev: {
  gnome = prev.gnome.overrideScope
    (final': prev': {
      mutter = prev'.mutter.overrideAttrs (old: {
        patches = (old.patches or []) ++ [
            (final.fetchpatch {
                url = "https://salsa.debian.org/gnome-team/mutter/-/raw/82e4a2c864e5e238bd03b1f4ef05f737915dac8c/debian/patches/ubuntu/x11-Add-support-for-fractional-scaling-using-Randr.patch";
                sha256 = "sha256-GCtz87C1NgxenYE5nbxcIIxqNhutmdngscnlK10fRyQ=";
            })
        ];
      });
    });
}
