{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.M1;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  hex2-0 = config.aux.foundation.stages.stage0.hex2-0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;
  M2 = config.aux.foundation.stages.stage0.M2;
  blood-elf = config.aux.foundation.stages.stage0.blood-elf;
  M1-0 = config.aux.foundation.stages.stage0.M1-0;
  hex2-1 = config.aux.foundation.stages.stage0.hex2-1;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;
in {
  options.aux.foundation.stages.stage0.M1 = {
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
      description = "The package to use for M1.";
    };
  };

  config = {
    aux.foundation.stages.stage0.M1 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "M1";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex2-1.package;

        args = let
          M1-macro_M1 = builders.raw.build {
            pname = "M1-macro_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M2.package;

            args = [
              "--architecture"
              architecture.m2libc
              "-f"
              "${sources.m2libc}/sys/types.h"
              "-f"
              "${sources.m2libc}/stddef.h"
              "-f"
              "${sources.m2libc}/${architecture.m2libc}/linux/unistd.c"
              "-f"
              "${sources.m2libc}/${architecture.m2libc}/linux/fcntl.c"
              "-f"
              "${sources.m2libc}/fcntl.c"
              "-f"
              "${sources.m2libc}/${architecture.m2libc}/linux/sys/stat.c"
              "-f"
              "${sources.m2libc}/string.c"
              "-f"
              "${sources.m2libc}/stdlib.c"
              "-f"
              "${sources.m2libc}/stdio.h"
              "-f"
              "${sources.m2libc}/stdio.c"
              "-f"
              "${sources.m2libc}/bootstrappable.c"
              "-f"
              "${sources.mescc-tools}/stringify.c"
              "-f"
              "${sources.mescc-tools}/M1-macro.c"
              "--debug"
              "-o"
              (builtins.placeholder "out")
            ];
          };
          M1-macro-footer_M1 = builders.raw.build {
            pname = "M1-macro-footer_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = blood-elf.package;

            args =
              (lib.lists.when (config.aux.platform.bits == 64) "--64")
              ++ [
                "-f"
                M1-macro_M1
                (
                  if config.aux.platform.endian == "little"
                  then "--little-endian"
                  else "--big-endian"
                )
                "-o"
                (builtins.placeholder "out")
              ];
          };
          M1-macro_hex2 = builders.raw.build {
            pname = "M1-macro_hex2";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M1-0.package;

            args = [
              "--architecture"
              architecture.m2libc
              (
                if config.aux.platform.endian == "little"
                then "--little-endian"
                else "--big-endian"
              )
              "-f"
              "${sources.m2libc}/${architecture.m2libc}/${architecture.m2libc}_defs.M1"
              "-f"
              "${sources.m2libc}/${architecture.m2libc}/libc-full.M1"
              "-f"
              M1-macro_M1
              "-f"
              M1-macro-footer_M1
              "-o"
              (builtins.placeholder "out")
            ];
          };
        in [
          "--architecture"
          architecture.m2libc
          (
            if config.aux.platform.endian == "little"
            then "--little-endian"
            else "--big-endian"
          )
          "--base-address"
          (
            if config.aux.system == "x86_64-linux"
            then "0x00600000"
            else if config.aux.system == "aarch64-linux"
            then "0x00600000"
            else if config.aux.system == "i686-linux"
            then "0x08048000"
            else builtins.throw "Unsupported system: ${config.aux.system}"
          )
          "-f"
          "${sources.m2libc}/${architecture.m2libc}/ELF-${architecture.m2libc}-debug.hex2"
          "-f"
          M1-macro_hex2
          "-o"
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
