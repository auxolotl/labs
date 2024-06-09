{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.heirloom.devtools;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
  stage1 = config.aux.foundation.stages.stage1;
  stage2 = config.aux.foundation.stages.stage2;
in {
  options.aux.foundation.stages.stage1.heirloom.devtools = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for heirloom-devtools.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.derivation;
      description = "Source for the package.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Portable yacc and lex derived from OpenSolaris";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://heirloom.sourceforge.net/devtools.html";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.list.of lib.types.attrs.any;
        description = "License for the package.";
        default.value = [
          lib.licenses.cddl
          lib.licenses.bsdOriginalUC
          lib.licenses.caldera
        ];
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.heirloom.devtools = {
      version = "070527";

      src = builtins.fetchurl {
        url = "https://downloads.sourceforge.net/heirloom/heirloom-devtools/heirloom-devtools-${cfg.version}.tar.bz2";
        sha256 = "9f233d8b78e4351fe9dd2d50d83958a0e5af36f54e9818521458a08e058691ba";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # See https://github.com/fosslinux/live-bootstrap/blob/d918b984ad6fe4fc7680f3be060fd82f8c9fddd9/sysa/heirloom-devtools-070527/heirloom-devtools-070527.kaem
        liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/d918b984ad6fe4fc7680f3be060fd82f8c9fddd9/sysa/heirloom-devtools-070527";

        patches = [
          # Remove all kinds of wchar support. Mes Libc does not support wchar in any form
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/yacc_remove_wchar.patch";
            sha256 = "0wgiz02bb7xzjy2gnbjp8y31qy6rc4b29v01zi32zh9lw54j68hc";
          })
          # Similarly to yacc, remove wchar. See yacc patch for further information
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/lex_remove_wchar.patch";
            sha256 = "168dfngi51ljjqgd55wbvmffaq61gk48gak50ymnl1br92qkp4zh";
          })
        ];
      in
        builders.kaem.build {
          name = "heirloom-${cfg.version}";
          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.coreutils.package
            stage0.mescc-tools-extra.package
          ];

          script = ''
            # Unpack
            unbz2 --file ${cfg.src} --output heirloom-devtools.tar
            untar --file heirloom-devtools.tar
            rm heirloom-devtools.tar
            build=''${NIX_BUILD_TOP}/heirloom-devtools-${cfg.version}
            cd ''${build}

            # Patch
            ${lib.strings.concatMapSep "\n" (f: "patch -Np0 -i ${f}") patches}

            # Build yacc
            cd yacc
            make -f Makefile.mk \
              CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib" \
              AR="tcc -ar" \
              CFLAGS="-DMAXPATHLEN=4096 -DEILSEQ=84 -DMB_LEN_MAX=100" \
              LDFLAGS="-lgetopt" \
              RANLIB=true \
              LIBDIR=''${out}/lib

            # Install yacc
            install -D yacc ''${out}/bin/yacc
            install -Dm 444 liby.a ''${out}/lib/liby.a
            install -Dm 444 yaccpar ''${out}/lib/yaccpar

            # Make yacc available to lex
            PATH="''${out}/bin:''${PATH}"

            # Build lex
            cd ../lex
            make -f Makefile.mk \
              CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib" \
              AR="tcc -ar" \
              CFLAGS="-DEILSEQ=84 -DMB_LEN_MAX=100" \
              LDFLAGS="-lgetopt" \
              RANLIB=true \
              LIBDIR=''${out}/lib

            # Install lex
            install -D lex ''${out}/bin/lex
            install -Dm 444 ncform ''${out}/lib/lex/ncform
            install -Dm 444 nceucform ''${out}/lib/lex/nceucform
            install -Dm 444 nrform ''${out}/lib/lex/nrform
            install -Dm 444 libl.a ''${out}/lib/libl.a
          '';
        };
    };
  };
}
