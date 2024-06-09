{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.M2;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  hex2-0 = config.aux.foundation.stages.stage0.hex2-0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;
in {
  options.aux.foundation.stages.stage0.M2 = {
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
      description = "The package to use for M2.";
    };
  };

  config = {
    aux.foundation.stages.stage0.M2 = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "M2";
        version = "1.6.0";

        meta = cfg.meta;

        executable = hex2-0.package;

        args = let
          M2_c = builders.raw.build {
            pname = "M2_c";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${sources.m2libc}/${architecture.m2libc}/linux/bootstrap.c"
              "${sources.m2planet}/cc.h"
              "${sources.m2libc}/bootstrappable.c"
              "${sources.m2planet}/cc_globals.c"
              "${sources.m2planet}/cc_reader.c"
              "${sources.m2planet}/cc_strings.c"
              "${sources.m2planet}/cc_types.c"
              "${sources.m2planet}/cc_core.c"
              "${sources.m2planet}/cc_macro.c"
              "${sources.m2planet}/cc.c"
            ];
          };
          M2_M1 = builders.raw.build {
            pname = "M2_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = cc_arch.package;

            args = [
              M2_c
              (builtins.placeholder "out")
            ];
          };
          M2_M1' = builders.raw.build {
            pname = "M2_M1";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${sources.m2libc}/${architecture.m2libc}/${architecture.m2libc}_defs.M1"
              "${sources.m2libc}/${architecture.m2libc}/libc-core.M1"
              M2_M1
            ];
          };
          M2_hex2-0 = builders.raw.build {
            pname = "M2_hex2-0";
            version = "1.6.0";

            meta = cfg.meta;

            executable = M0.package;

            args = [
              M2_M1'
              (builtins.placeholder "out")
            ];
          };
          M2_hex2-0' = builders.raw.build {
            pname = "M2_hex2-0";
            version = "1.6.0";

            meta = cfg.meta;

            executable = catm.package;

            args = [
              (builtins.placeholder "out")
              "${sources.m2libc}/${architecture.m2libc}/ELF-${architecture.m2libc}.hex2"
              M2_hex2-0
            ];
          };
        in [
          M2_hex2-0'
          (builtins.placeholder "out")
        ];
      });
    };
  };
}
