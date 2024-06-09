{system ? builtins.currentSystem}: let
  lib = import ./../lib;

  modules = import ./src;

  result = lib.modules.run {
    modules =
      (builtins.attrValues modules)
      ++ [
        {config.aux.system = system;}
      ];
  };
in
  result.config.exports.resolved.packages
