{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.mes.libc;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.mes.libc = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "The Mes C Library";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://gnu.org/software/mes";
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
      description = "The package to use for mes-libc.";
    };
  };

  config = {
    aux.foundation.stages.stage1.mes.libc = {
      package = let
        sources = import ./sources.nix;

        libtcc1 = sources.x86.linux.gcc.libtcc1;

        first = lib.lists.take 100 sources.x86.linux.gcc.libc_gnu;
        last = lib.lists.drop 100 sources.x86.linux.gcc.libc_gnu;
      in
        builders.kaem.build {
          name = "mes-libc-${stage1.mes.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.ln-boot.package
          ];

          script = ''
            cd ${stage1.mes.libs.prefix}

            # mescc compiled libc.a
            mkdir -p ''${out}/lib/x86-mes

            # libc.c
            catm ''${TMPDIR}/first.c ${builtins.concatStringsSep " " first}
            catm ''${out}/lib/libc.c ''${TMPDIR}/first.c ${builtins.concatStringsSep " " last}

            # crt{1,n,i}.c
            cp lib/linux/x86-mes-gcc/crt1.c ''${out}/lib
            cp lib/linux/x86-mes-gcc/crtn.c ''${out}/lib
            cp lib/linux/x86-mes-gcc/crti.c ''${out}/lib

            # libtcc1.c
            catm ''${out}/lib/libtcc1.c ${builtins.concatStringsSep " " libtcc1}

            # getopt.c
            cp lib/posix/getopt.c ''${out}/lib/libgetopt.c

            # Install headers
            ln -s ${stage1.mes.libs.prefix}/include ''${out}/include
          '';

          extras = {
            CFLAGS = "-DHAVE_CONFIG_H=1 -I${cfg.package}/include -I${cfg.package}/include/linux/x86";
          };
        };
    };
  };
}
