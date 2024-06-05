{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.hex2-1;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  hex2-0 = config.aux.foundation.stages.stage0.hex2-0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;
  M2 = config.aux.foundation.stages.stage0.M2;
  blood-elf = config.aux.foundation.stages.stage0.blood-elf;
  M1-0 = config.aux.foundation.stages.stage0.M1-0;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
in {
  options.aux.foundation.stages.stage0.hex2-1 = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for hex2-1.";
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
    aux.foundation.stages.stage0.hex2-1 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "hex2-1";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex2-0.package;

        args = let
          hex2_linker_M1 = builders.raw.build {
            pname = "hex2_linker_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M2.package;

            args = [
              "--architecture"
              hex0.m2libc.architecture
              "-f"
              "${hex0.m2libc.src}/sys/types.h"
              "-f"
              "${hex0.m2libc.src}/stddef.h"
              "-f"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/linux/unistd.c"
              "-f"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/linux/fcntl.c"
              "-f"
              "${hex0.m2libc.src}/fcntl.c"
              "-f"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/linux/sys/stat.c"
              "-f"
              "${hex0.m2libc.src}/stdlib.c"
              "-f"
              "${hex0.m2libc.src}/stdio.h"
              "-f"
              "${hex0.m2libc.src}/stdio.c"
              "-f"
              "${hex0.m2libc.src}/bootstrappable.c"
              "-f"
              "${hex0.mescc-tools.src}/hex2.h"
              "-f"
              "${hex0.mescc-tools.src}/hex2_linker.c"
              "-f"
              "${hex0.mescc-tools.src}/hex2_word.c"
              "-f"
              "${hex0.mescc-tools.src}/hex2.c"
              "--debug"
              "-o"
              (builtins.placeholder "out")
            ];
          };
          hex2_linker-footer_M1 = builders.raw.build {
            pname = "hex2_linker-footer_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = blood-elf.package;

            args =
              (lib.lists.when (config.aux.platform.bits == 64) "--64")
              ++ [
                "-f"
                hex2_linker_M1
                (
                  if config.aux.platform.endian == "little"
                  then "--little-endian"
                  else "--big-endian"
                )
                "-o"
                (builtins.placeholder "out")
              ];
          };
          hex2_linker_hex2 = builders.raw.build {
            pname = "hex2_linker_hex2";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M1-0.package;

            args = [
              "--architecture"
              hex0.m2libc.architecture
              (
                if config.aux.platform.endian == "little"
                then "--little-endian"
                else "--big-endian"
              )
              "-f"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/${hex0.m2libc.architecture}_defs.M1"
              "-f"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/libc-full.M1"
              "-f"
              hex2_linker_M1
              "-f"
              hex2_linker-footer_M1
              "-o"
              (builtins.placeholder "out")
            ];
          };
          hex2_linker_hex2' = builders.raw.build {
            pname = "hex2_linker_hex2-1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/ELF-${hex0.m2libc.architecture}-debug.hex2"
              hex2_linker_hex2
            ];
          };
        in [
          hex2_linker_hex2'
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
