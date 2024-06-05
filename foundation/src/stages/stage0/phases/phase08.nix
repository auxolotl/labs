{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.M1-0;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  hex2-0 = config.aux.foundation.stages.stage0.hex2-0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;
  M2 = config.aux.foundation.stages.stage0.M2;
  blood-elf = config.aux.foundation.stages.stage0.blood-elf;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;
in {
  options.aux.foundation.stages.stage0.M1-0 = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for M1-0.";
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
    aux.foundation.stages.stage0.M1-0 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "M1-0";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex2-0.package;

        args = let
          M1-macro-0_M1 = builders.raw.build {
            pname = "M1-macro-0_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M2.package;

            args = [
              "--architecture"
              architecture.m2libc
              "-f"
              "${sources.m2libc}/${architecture.m2libc}/linux/bootstrap.c"
              "-f"
              "${sources.m2libc}/bootstrappable.c"
              "-f"
              "${sources.mescc-tools}/stringify.c"
              "-f"
              "${sources.mescc-tools}/M1-macro.c"
              "--bootstrap-mode"
              "--debug"
              "-o"
              (builtins.placeholder "out")
            ];
          };
          M1-macro-0-footer_M1 = builders.raw.build {
            pname = "M1-macro-0-footer_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = blood-elf.package;

            args =
              (lib.lists.when (config.aux.platform.bits == 64) "--64")
              ++ [
                "-f"
                M1-macro-0_M1
                (
                  if config.aux.platform.endian == "little"
                  then "--little-endian"
                  else "--big-endian"
                )
                "-o"
                (builtins.placeholder "out")
              ];
          };
          M1-macro-0_M1' = builders.raw.build {
            pname = "M1-macro-0_M1-1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${sources.m2libc}/${architecture.m2libc}/${architecture.m2libc}_defs.M1"
              "${sources.m2libc}/${architecture.m2libc}/libc-core.M1"
              M1-macro-0_M1
              M1-macro-0-footer_M1
            ];
          };
          M1-macro-0_hex2-0 = builders.raw.build {
            pname = "M1-macro-0_hex2-0";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M0.package;

            args = [
              M1-macro-0_M1'
              (builtins.placeholder "out")
            ];
          };
          M1-macro-0_hex2-0' = builders.raw.build {
            pname = "M1-macro-0_hex2-0-1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${sources.m2libc}/${architecture.m2libc}/ELF-${architecture.m2libc}-debug.hex2"
              M1-macro-0_hex2-0
            ];
          };
        in [
          M1-macro-0_hex2-0'
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
