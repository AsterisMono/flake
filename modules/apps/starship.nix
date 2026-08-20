{
  flake.modules.homeManager.starship = {
    programs.starship = {
      enable = true;
      enableFishIntegration = true;
      enableTransience = true;
      settings = {
        right_format = "$memory_usage$battery$time";

        character = {
          format = "$symbol ";
          success_symbol = "[](fg:#5BCEFA)[](bg:#F5A9B8 fg:#5BCEFA)[](bg:#FFFFFF fg:#F5A9B8)[](bg:#F5A9B8 fg:#FFFFFF)[](bg:#5BCEFA fg:#F5A9B8)[](fg:#5BCEFA)";
          error_symbol = "[](fg:#5BCEFA)[](bg:#F5A9B8 fg:#5BCEFA)[](bg:#FFFFFF fg:#F5A9B8)[](bg:#F5A9B8 fg:#FFFFFF)[](bg:#5BCEFA fg:#F5A9B8)[](fg:#5BCEFA)";
        };

        battery = {
          format = "[$symbol$percentage]($style) / ";
          display = [
            {
              threshold = 100;
              style = "bold green";
            }
          ];
        };

        memory_usage = {
          disabled = false;
          format = "[$ram_pct]($style) / ";
          threshold = -1;
          symbol = "";
        };

        time = {
          disabled = false;
          format = "[$time]($style) ";
          time_format = "%R";
          utc_time_offset = "+8";
        };
      };
    };
  };
}
