{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.hex1;
  hex0 = config.aux.foundation.stages.stage0.hex0;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;
in {
  options.aux.foundation.stages.stage0.hex1 = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Collection of tools for use in bootstrapping.";
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
      description = "The package to use for hex1.";
    };
  };

  config = {
    aux.foundation.stages.stage0.hex1 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "hex1";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex0.package;

        args = [
          "${sources.base}/hex1_${architecture.base}.hex0"
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
