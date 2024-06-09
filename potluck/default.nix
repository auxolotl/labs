{
  lib ? import ./../lib,
  foundation ? import ./../foundation {system = "i686-linux";},
}: let
  modules = import ./src/modules.nix;

  result = lib.modules.run {
    modules =
      modules
      ++ [
        {
          __file__ = ./default.nix;

          options.aux.packages.foundation = {
            raw = lib.options.create {
              type = lib.types.attrs.of lib.types.package;
              internal = true;
              description = "The foundational packages used to construct the larger package set.";
            };
          };

          config.aux.packages.foundation = {
            raw = foundation;
          };
        }
      ];
  };
in
  result.config.exported
