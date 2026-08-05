{
  my.services.dst-server.instances.main = {
    settings = {
      cluster = {
        GAMEPLAY = {
          game_mode = "endless";
          max_players = 6;
          pause_when_empty = true;
          pvp = false;
        };
        MISC.console_enabled = true;
        NETWORK = {
          cluster_name = "Diffumist DST Server";
          cluster_description = "A Don't Starve Together server hosted on NixOS";
          cluster_intention = "social";
          lan_only_cluster = false;
          offline_cluster = false;
        };
        SHARD.master_port = 10888;
      };

      master = {
        ACCOUNT.encode_user_path = true;
        NETWORK.server_port = 10999;
        STEAM = {
          authentication_port = 8766;
          master_server_port = 27016;
        };
      };

      caves = {
        ACCOUNT.encode_user_path = true;
        NETWORK.server_port = 11000;
        STEAM = {
          authentication_port = 8767;
          master_server_port = 27017;
        };
      };

      worldgen = {
        master = {
          preset = "ENDLESS";
          overrides = {
            branching = "most";
            ocean_seastack = "ocean_default";
            ocean_waterplant = "ocean_default";
            roads = "never";
            start_location = "plus";
            world_size = "small";
            basicresource_regrowth = "always";
            extrastartingitems = "0";
            ghostenabled = "always";
            ghostsanitydrain = "none";
            grassgekkos = "never";
            healthpenalty = "always";
            lessdamagetaken = "none";
            mutated_buzzard_gestalt = "never";
            portalresurection = "always";
            resettime = "none";
            spawnmode = "fixed";
            spawnprotection = "always";
            twiggytrees_regrowth = "never";
            wanderingtrader_enabled = "always";
            wildfires = "never";
            winters_feast = "enabled";
            year_of_the_dragonfly = "enabled";
            year_of_the_knight = "enabled";
            year_of_the_pig = "enabled";
          };
        };
        caves = {
          preset = "DST_CAVE";
          overrides = {
            branching = "most";
            start_location = "caves";
            task_set = "cave_default";
            world_size = "small";
            acidrain_enabled = "always";
            grassgekkos = "never";
            mushgnome = "always";
            twiggytrees_regrowth = "never";
          };
        };
      };
    };

    mods = [
      "1185229307"
      "1207269058"
      "1378549454"
      "1916988643"
      "2189004162"
      "2484725102"
      "2621090176"
      "2941527805"
      "3050607025"
      "3278569745"
      "3459779337"
      "3485293431"
      "3532153780"
      "3535964924"
      "3543168000"
      "3606652330"
      "3621180063"
      "3624411781"
      "3645075395"
      "3703272454"
      "3742464934"
      "3750536829"
      "3751709390"
      "3760106287"
    ];
  };
}
