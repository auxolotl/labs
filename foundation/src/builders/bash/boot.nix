{
  lib,
  config,
}: let
  system = config.aux.system;
  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.builders.bash.boot = {
    build = lib.options.create {
      type = lib.types.function lib.types.package;
      description = "Builds a package using the kaem builder.";
    };
  };

  config = {
    aux.foundation.builders.bash.boot = {
      build = lib.modules.overrides.default (settings @ {
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

            builder = "${stage1.bash.boot.package}/bin/bash";

            args = [
              "-e"
              (builtins.toFile "bash-builder.sh" ''
                export CONFIG_SHELL=$SHELL

                # Normalize the NIX_BUILD_CORES variable. The value might be 0, which
                # means that we're supposed to try and auto-detect the number of
                # available CPU cores at run-time. We don't have nproc to detect the
                # number of available CPU cores so default to 1 if not set.
                NIX_BUILD_CORES="''${NIX_BUILD_CORES:-1}"
                if [ $NIX_BUILD_CORES -le 0 ]; then
                  NIX_BUILD_CORES=1
                fi
                export NIX_BUILD_CORES

                bash -eux $scriptPath
              '')
            ];

            SHELL = "${stage1.bash.boot.package}/bin/bash";

            PATH = lib.paths.bin (
              (deps.build.host or [])
              ++ [
                stage1.bash.boot.package
                stage1.coreutils.boot.package
                stage0.mescc-tools-extra.package
              ]
            );
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
