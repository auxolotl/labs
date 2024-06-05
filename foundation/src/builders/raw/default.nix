{
  lib,
  config,
}: let
  system = config.aux.system;
in {
  options.aux.foundation.builders.raw = {
    build = lib.options.create {
      type = lib.types.function lib.types.package;
      description = "Builds a package using the raw builder.";
    };
  };

  config = {
    aux.foundation.builders.raw = {
      build = lib.modules.overrides.default (settings @ {
        pname,
        version,
        executable,
        args ? [],
        meta ? {},
        extras ? {},
        ...
      }: let
        package = builtins.derivation (
          (builtins.removeAttrs settings ["meta" "extras" "executable"])
          // {
            inherit version pname system args;

            name = "${pname}-${version}";

            builder = executable;
          }
        );
      in
        package
        // {
          inherit meta extras;
        });
    };
  };
}
