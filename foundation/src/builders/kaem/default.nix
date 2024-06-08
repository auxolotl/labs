{
  lib,
  config,
}: let
  system = config.aux.system;
  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
in {
  options.aux.foundation.builders.kaem = {
    build = lib.options.create {
      type = lib.types.function lib.types.package;
      description = "Builds a package using the kaem builder.";
    };
  };

  config = {
    aux.foundation.builders.kaem = {
      build = settings @ {
        name,
        script,
        meta ? {},
        extras ? {},
        env ? {},
        deps ? {},
        ...
      }: let
        package = builtins.derivation (
          (builtins.removeAttrs settings ["meta" "extras" "executable" "env" "deps" "script"])
          // env
          // {
            inherit name system;

            builder = "${stage0.kaem.package}/bin/kaem";

            args = [
              "--verbose"
              "--strict"
              "--file"
              (
                builders.file.text.build {
                  name = "${name}-builder";
                  contents = script;
                }
              )
            ];

            PATH = lib.paths.bin (
              (deps.build.host or [])
              ++ [
                stage0.kaem.package
                stage0.mescc-tools.package
                stage0.mescc-tools-extra.package
              ]
            );
          }
        );
      in
        package
        // {
          inherit meta extras;
        };
    };
  };
}
