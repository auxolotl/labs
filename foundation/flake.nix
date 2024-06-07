{
  description = "A set of foundational packages required for bootstrapping a larger package set.";

  inputs = {
    lib = {
      url = "path:../lib";
    };
  };

  outputs = inputs: let
    inherit (inputs.lib) lib;

    modules = import ./src;

    forEachSystem = lib.attrs.generate [
      # "x86_64-linux"
      # "aarch64-linux"
      "i686-linux"
      # "x86_64-darwin"
      # "aarch64-darwin"
    ];
  in {
    extras = let
      result = lib.modules.run {
        modules =
          builtins.attrValues modules;
      };
    in
      result.config.exports.resolved.extras;

    packages = forEachSystem (
      system: let
        result = lib.modules.run {
          modules =
            (builtins.attrValues modules)
            ++ [
              {config.aux.system = system;}
            ];
        };
      in
        result.config.exports.resolved.packages
    );
  };
}
