{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.blood-elf;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  hex2-0 = config.aux.foundation.stages.stage0.hex2-0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;
  M2 = config.aux.foundation.stages.stage0.M2;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
in {
  options.aux.foundation.stages.stage0.blood-elf = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for blood-elf.";
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
    aux.foundation.stages.stage0.blood-elf = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "blood-elf";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex2-0.package;

        args = let
          blood-elf_M1 = builders.raw.build {
            pname = "blood-elf_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M2.package;

            args = [
              "--architecture"
              hex0.m2libc.architecture
              "-f"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/linux/bootstrap.c"
              "-f"
              "${hex0.m2libc.src}/bootstrappable.c"
              "-f"
              "${hex0.mescc-tools.src}/stringify.c"
              "-f"
              "${hex0.mescc-tools.src}/blood-elf.c"
              "--bootstrap-mode"
              "-o"
              (builtins.placeholder "out")
            ];
          };
          blood-elf_M1' = builders.raw.build {
            pname = "blood-elf_M1-1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/${hex0.m2libc.architecture}_defs.M1"
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/libc-core.M1"
              blood-elf_M1
            ];
          };
          blood-elf_hex2-0 = builders.raw.build {
            pname = "blood-elf_hex2-0";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M0.package;

            args = [
              blood-elf_M1'
              (builtins.placeholder "out")
            ];
          };
          blood-elf_hex2-0' = builders.raw.build {
            pname = "blood-elf_hex2-0-1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${hex0.m2libc.src}/${hex0.m2libc.architecture}/ELF-${hex0.m2libc.architecture}.hex2"
              blood-elf_hex2-0
            ];
          };
        in [
          blood-elf_hex2-0'
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
