{
  lib,
  config,
}: let
  lib' = config.lib;

  configure = namespace: packages:
    builtins.mapAttrs
    (key: package: let
      name =
        if package.pname != null && package.version != null
        then "${package.pname}-${package.version}"
        else key;
    in {
      name = lib.modules.overrides.default name;
      package = lib.modules.overrides.default (package.builder package);
    })
    packages;

  configs = builtins.mapAttrs configure config.packages;
in {
  includes = [
    ./aux/foundation.nix
  ];

  options = {
    packages = lib.options.create {
      type = lib'.types.packages;
    };
  };

  config = lib.modules.merge configs;
}
