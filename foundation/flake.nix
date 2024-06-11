{
  description = "A set of foundational packages required for bootstrapping a larger package set.";

  inputs = {
    # TODO: When this project is moved to its own repository we will want to add
    # inputs for the relevant dependencies.
    # lib = {
    #   url = "path:../lib";
    # };
  };

  outputs = inputs: let
    # inherit (inputs.lib) lib;
    lib = import ./../lib;

    modules = import ./src;

    forEachSystem = lib.attrs.generate [
      "i686-linux"
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
