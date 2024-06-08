{
  lib,
  config,
}: let
  system = config.aux.system;

  stage0 = config.aux.foundation.stages.stage0;
in {
  options.aux.foundation.builders.file.text = {
    build = lib.options.create {
      type = lib.types.function lib.types.package;
      description = "Builds a package using the text file builder.";
    };
  };

  config = {
    aux.foundation.builders.file.text = {
      build = settings @ {
        name,
        contents,
        isExecutable ? false,
        destination ? "",
        meta ? {},
        extras ? {},
        ...
      }: let
        script =
          ''
            target=''${out}''${destination}
          ''
          + lib.strings.when (builtins.dirOf destination == ".") ''
            mkdir -p ''${out}''${destinationDir}
          ''
          + ''
            cp ''${contentsPath} ''${target}
          ''
          + lib.strings.when isExecutable ''
            chmod 555 ''${target}
          '';
        package = builtins.derivation (
          (builtins.removeAttrs settings ["meta" "extras" "executable" "isExecutable"])
          // {
            inherit name system destination contents;
            destinationDir = builtins.dirOf destination;

            passAsFile = ["contents"];

            builder = "${stage0.kaem.package}/bin/kaem";

            args = [
              "--verbose"
              "--strict"
              "--file"
              (builtins.toFile "write-text-to-file.kaem" script)
            ];

            PATH = lib.paths.bin [
              stage0.mescc-tools-extra.package
            ];
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
