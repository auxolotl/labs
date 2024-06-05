{
  lib,
  config,
}: let
  system = config.aux.system;
in {
  options.aux.foundation.builders.file.text = {
    build = lib.options.create {
      type = lib.types.function lib.types.package;
      description = "Builds a package using the text file builder.";
    };
  };

  config = {
    aux.foundation.builders.file.text = {
      build = lib.modules.overrides.default (settings @ {
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
            cp ''${contentPath} ''${target}
          ''
          + lib.strings.when isExecutable ''
            chmod 555 ''${target}
          '';
        package = builtins.derivation (
          (builtins.removeAttrs settings ["meta" "extras" "executable" "isExecutable"])
          // {
            inherit name system contents destination;
            destinationDir = builtins.dirOf destination;

            passAsFile = ["contents"];

            builder = "${config.aux.foundation.stages.stage0.kaem.package}/bin/kaem";

            args = [
              "--verbose"
              "--strict"
              "--file"
              (builtins.toFile "write-text-to-file.kaem" script)
            ];
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
