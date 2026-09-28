{
  flake.modules.homeManager.kanshi =
    { lib, ... }:
    {
      # Monitor plans are authored here and on machines.<name>.homeModule.
      # Kanshi picks the first profile whose outputs match the connected heads
      # one-to-one, so host profiles stay at the default merge order and this
      # single-output fallback stays last.
      services.kanshi = {
        enable = true;
        settings = lib.mkAfter [
          {
            profile.name = "fallback-single";
            profile.outputs = [
              {
                criteria = "*";
                status = "enable";
              }
            ];
          }
        ];
      };
    };
}
