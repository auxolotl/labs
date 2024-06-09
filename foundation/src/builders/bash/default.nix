{
  lib,
  config,
}: let
  system = config.aux.system;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.builders.bash = {
    build = lib.options.create {
      type = lib.types.function lib.types.derivation;
      description = "Builds a package using the bash builder.";
    };
  };

  config = {
    aux.foundation.builders.bash = {
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
            inherit name system script;

            passAsFile = ["script"];

            builder = "${stage1.bash.package}/bin/bash";

            args = [
              "-e"
              (builtins.toFile "bash-builder.sh" ''
                export CONFIG_SHELL=$SHELL

                # Normalize the NIX_BUILD_CORES variable. The value might be 0, which
                # means that we're supposed to try and auto-detect the number of
                # available CPU cores at run-time.
                NIX_BUILD_CORES="''${NIX_BUILD_CORES:-1}"
                if ((NIX_BUILD_CORES <= 0)); then
                  guess=$(nproc 2>/dev/null || true)
                  ((NIX_BUILD_CORES = guess <= 0 ? 1 : guess))
                fi
                export NIX_BUILD_CORES

                bash -eux $scriptPath
              '')
            ];

            SHELL = "${stage1.bash.package}/bin/bash";

            PATH = lib.paths.bin (
              (deps.build.host or [])
              ++ [
                stage1.bash.package
                stage1.coreutils.package
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
