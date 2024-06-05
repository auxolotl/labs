{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.mescc-tools-extra;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;
  M2 = config.aux.foundation.stages.stage0.M2;
  blood-elf = config.aux.foundation.stages.stage0.blood-elf;
  M1 = config.aux.foundation.stages.stage0.M1;
  hex2 = config.aux.foundation.stages.stage0.hex2;
  kaem-unwrapped = config.aux.foundation.stages.stage0.kaem-unwrapped;
  mescc-tools = config.aux.foundation.stages.stage0.mescc-tools;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;
in {
  options.aux.foundation.stages.stage0.mescc-tools-extra = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for mescc-tools-extra.";
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
    aux.foundation.stages.stage0.mescc-tools-extra = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "mescc-tools-tools";
        version = "1.6.0";

        meta = cfg.meta;

        executable = kaem-unwrapped.package;

        args = [
          "--verbose"
          "--strict"
          "--file"
          ./build.kaem
        ];

        src = sources.mescc-tools-extra;

        m2libcOS = "linux";
        m2libcArch = architecture.m2libc;
        mesccTools = mescc-tools.package;
      });
    };
  };
}
