{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.mes.libs;

  system = config.aux.system;
  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.mes.libs = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for mes libs.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Scheme interpreter and C compiler for bootstrapping.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/mes";
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

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    prefix = lib.options.create {
      type = lib.types.string;
      description = "Prefix for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.mes.libs = {
      prefix = "${cfg.src.out}/mes-${stage1.mes.version}";

      src = let
        config_h = builtins.toFile "config.h" ''
          #undef SYSTEM_LIBC
          #define MES_VERSION "${stage1.mes.version}"
        '';
      in
        builders.kaem.build {
          name = "mes-src-${stage1.mes.version}";

          meta = cfg.meta;

          outputs = [
            "out"
            "bin"
          ];

          script = ''
            # Unpack source
            ungz --file ${stage1.mes.src} --output mes.tar
            mkdir ''${out}
            cd ''${out}
            untar --non-strict --file ''${NIX_BUILD_TOP}/mes.tar # ignore symlinks

            MES_PREFIX=''${out}/mes-${stage1.mes.version}

            cd ''${MES_PREFIX}

            cp ${config_h} include/mes/config.h

            mkdir include/arch
            cp include/linux/x86/syscall.h include/arch/syscall.h
            cp include/linux/x86/kernel-stat.h include/arch/kernel-stat.h

            # Remove pregenerated files
            rm mes/module/mes/psyntax.pp mes/module/mes/psyntax.pp.header

            # These files are symlinked in the repo
            cp mes/module/srfi/srfi-9-struct.mes mes/module/srfi/srfi-9.mes
            cp mes/module/srfi/srfi-9/gnu-struct.mes mes/module/srfi/srfi-9/gnu.mes

            # Remove environment impurities
            __GUILE_LOAD_PATH="\"''${MES_PREFIX}/mes/module:''${MES_PREFIX}/module:${stage1.nyacc.package.extras.guileModule}\""
            boot0_scm=mes/module/mes/boot-0.scm
            guile_mes=mes/module/mes/guile.mes
            replace --file ''${boot0_scm} --output ''${boot0_scm} --match-on "(getenv \"GUILE_LOAD_PATH\")" --replace-with ''${__GUILE_LOAD_PATH}
            replace --file ''${guile_mes} --output ''${guile_mes} --match-on "(getenv \"GUILE_LOAD_PATH\")" --replace-with ''${__GUILE_LOAD_PATH}

            module_mescc_scm=module/mescc/mescc.scm
            replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"M1\")" --replace-with "\"${stage0.mescc-tools.package}/bin/M1\""
            replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"HEX2\")" --replace-with "\"${stage0.mescc-tools.package}/bin/hex2\""
            replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"BLOOD_ELF\")" --replace-with "\"${stage0.mescc-tools.package}/bin/blood-elf\""
            replace --file ''${module_mescc_scm} --output ''${module_mescc_scm} --match-on "(getenv \"srcdest\")" --replace-with "\"''${MES_PREFIX}\""

            mes_c=src/mes.c
            replace --file ''${mes_c} --output ''${mes_c} --match-on "getenv (\"MES_PREFIX\")" --replace-with "\"''${MES_PREFIX}\""
            replace --file ''${mes_c} --output ''${mes_c} --match-on "getenv (\"srcdest\")" --replace-with "\"''${MES_PREFIX}\""

            # Increase runtime resource limits
            gc_c=src/gc.c
            replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_ARENA\")" --replace-with "\"100000000\""
            replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_MAX_ARENA\")" --replace-with "\"100000000\""
            replace --file ''${gc_c} --output ''${gc_c} --match-on "getenv (\"MES_STACK\")" --replace-with "\"6000000\""

            # Create mescc.scm
            mescc_in=scripts/mescc.scm.in
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"MES_PREFIX\")" --replace-with "\"''${MES_PREFIX}\""
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"includedir\")" --replace-with "\"''${MES_PREFIX}/include\""
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on "(getenv \"libdir\")" --replace-with "\"''${MES_PREFIX}/lib\""
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on @prefix@ --replace-with ''${MES_PREFIX}
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on @VERSION@ --replace-with ${stage1.mes.version}
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on @mes_cpu@ --replace-with x86
            replace --file ''${mescc_in} --output ''${mescc_in} --match-on @mes_kernel@ --replace-with linux
            mkdir -p ''${bin}/bin
            cp ''${mescc_in} ''${bin}/bin/mescc.scm

            # Build mes-m2
            kaem --verbose --strict --file kaem.x86
            cp bin/mes-m2 ''${bin}/bin/mes-m2
            chmod 555 ''${bin}/bin/mes-m2
          '';
        };

      package = let
        compile = path: let
          file = builtins.baseNameOf path;
          fileWithoutExtension = builtins.replaceStrings [".c"] [""] file;

          cc = builtins.concatStringsSep " " [
            "${cfg.src.bin}/bin/mes-m2"
            "-e"
            "main"
            "${cfg.src.bin}/bin/mescc.scm"
            "--"
            "-D"
            "HAVE_CONFIG_H=1"
            "-I"
            "${cfg.prefix}/include"
            "-I"
            "${cfg.prefix}/include/linux/x86"
          ];
        in
          builders.kaem.build {
            name = fileWithoutExtension;

            script = ''
              mkdir ''${out}
              cd ''${out}
              ${cc} -c ${cfg.prefix}/${path}
            '';
          };

        getSourcePath = suffix: source: "${source}/${source.name}${suffix}";

        archive = destination: sources: "catm ${destination} ${lib.strings.concatMapSep " " (getSourcePath ".o") sources}";
        source = destination: sources: "catm ${destination} ${lib.strings.concatMapSep " " (getSourcePath ".s") sources}";

        createLib = name: sources: let
          compiled = builtins.map compile sources;
        in
          builders.kaem.build {
            name = "mes-${name}-${stage1.mes.version}";

            meta = cfg.meta;

            script = ''
              LIBDIR=''${out}/lib
              mkdir -p ''${LIBDIR}
              cd ''${LIBDIR}

              ${archive "${name}.a" compiled}
              ${source "${name}.s" compiled}

            '';
          };

        sources = import ./sources.nix;

        crt1 = compile "lib/linux/x86-mes-mescc/crt1.c";
        libc-mini = createLib "libc-mini" sources.x86.linux.mescc.libc_mini;
        libmescc = createLib "libmescc" sources.x86.linux.mescc.libmescc;
        libc = createLib "libc" sources.x86.linux.mescc.libc;
        libc_tcc = createLib "libc+tcc" (sources.x86.linux.mescc.libc_tcc ++ ["lib/linux/symlink.c"]);
      in
        builders.kaem.build {
          name = "mes-m2-libs-${stage1.mes.version}";

          meta = cfg.meta;

          script = ''
            LIBDIR=''${out}/lib
            mkdir -p ''${out} ''${LIBDIR}

            mkdir -p ''${LIBDIR}/x86-mes

            # crt1.o
            cp ${crt1}/crt1.o ''${LIBDIR}/x86-mes
            cp ${crt1}/crt1.s ''${LIBDIR}/x86-mes

            # libc-mini.a
            cp ${libc-mini}/lib/libc-mini.a ''${LIBDIR}/x86-mes
            cp ${libc-mini}/lib/libc-mini.s ''${LIBDIR}/x86-mes

            # libmescc.a
            cp ${libmescc}/lib/libmescc.a ''${LIBDIR}/x86-mes
            cp ${libmescc}/lib/libmescc.s ''${LIBDIR}/x86-mes

            # libc.a
            cp ${libc}/lib/libc.a ''${LIBDIR}/x86-mes
            cp ${libc}/lib/libc.s ''${LIBDIR}/x86-mes

            # libc+tcc.a
            cp ${libc_tcc}/lib/libc+tcc.a ''${LIBDIR}/x86-mes
            cp ${libc_tcc}/lib/libc+tcc.s ''${LIBDIR}/x86-mes
          '';
        };
    };
  };
}
