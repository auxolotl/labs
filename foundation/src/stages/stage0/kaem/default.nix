{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.kaem;

  system = config.aux.system;
  builders = config.aux.foundation.builders;

  kaem-unwrapped = config.aux.foundation.stages.stage0.kaem-unwrapped;
  mescc-tools = config.aux.foundation.stages.stage0.mescc-tools;
  mescc-tools-extra = config.aux.foundation.stages.stage0.mescc-tools-extra;
in {
  options.aux.foundation.stages.stage0.kaem = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Minimal build tool for running scripts on systems that lack any shell.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://github.com/oriansj/stage0-posix";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl3Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for kaem.";
    };
  };

  config = {
    aux.foundation.stages.stage0.kaem = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "kaem";
        version = "1.6.0";

        meta = cfg.meta;

        executable = kaem-unwrapped.package;

        args = [
          "--verbose"
          "--strict"
          "--file"
          ./build.kaem
        ];

        kaemUnwrapped = kaem-unwrapped.package;
        PATH = lib.paths.bin [mescc-tools-extra.package];
      });
    };
  };
}
