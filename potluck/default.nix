{
  lib ? import ./../lib,
  foundation ? import ./../foundation {system = "i686-linux";},
}: let
  modules = import ./src/modules.nix;

  result = lib.modules.run {
    modules =
      (builtins.attrValues modules)
      ++ [
        ./src/export.nix
        {
          __file__ = ./default.nix;

          options.packages.aux = {
            foundation = lib.options.create {
              type = lib.types.attrs.of lib.types.package;
              internal = true;
              description = "The foundational packages used to construct the larger package set.";
            };
          };

          config.packages.aux = {
            foundation = foundation;
          };
        }
      ];
  };
in
  result.config.exported
