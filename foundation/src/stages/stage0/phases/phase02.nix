{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.hex2-0;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  hex1 = config.aux.foundation.stages.stage0.hex1;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;
in {
  options.aux.foundation.stages.stage0.hex2-0 = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for hex2-0.";
    };

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
        default.value = ["x86_64-linux" "aarch64-linux" "i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage0.hex2-0 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "hex2-0";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex1.package;

        args = [
          "${sources.base}/hex2_${architecture.base}.hex1"
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
