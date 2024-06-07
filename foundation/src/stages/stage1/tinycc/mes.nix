args @ {
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.tinycc.mes;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;

  pname = "tinycc-boot";

  helpers = lib.fp.withDynamicArgs (import ./helpers.nix) args;
in {
  options.aux.foundation.stages.stage1.tinycc.mes = {
    compiler = {
      package = lib.options.create {
        type = lib.types.package;
        description = "The package to use for the tinycc-mes compiler.";
      };
    };

    libs = {
      package = lib.options.create {
        type = lib.types.package;
        description = "The package to use for the tinycc-mes libs.";
      };
    };

    src = lib.options.create {
      type = lib.types.string;
      description = "Source for the package.";
    };

    revision = lib.options.create {
      type = lib.types.string;
      description = "Revision of the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.tinycc.mes = let
      tinycc-mes = let
        tccdefs = builders.kaem.build {
          name = "tccdefs-${stage1.tinycc.version}";

          script = ''
            mkdir ''${out}
            ${stage1.tinycc.boot.compiler.package}/bin/tcc \
              -B ${stage1.tinycc.boot.libs.package}/lib \
              -DC2STR \
              -o c2str \
              ${cfg.src}/conftest.c
            ./c2str ${cfg.src}/include/tccdefs.h ''${out}/tccdefs_.h
          '';
        };

        tinycc-mes-boot = helpers.createTinyccMes {
          pname = "tinycc-mes-boot";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-D HAVE_BITFIELD=1"
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
            "-D HAVE_SETJMP=1"
            "-D CONFIG_TCC_PREDEFS=1"
            "-I ${tccdefs}"
            "-D CONFIG_TCC_SEMLOCK=0"
          ];
          lib.args = [
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
            "-D CONFIG_TCC_PREDEFS=1"
            "-I ${tccdefs}"
            "-D CONFIG_TCC_SEMLOCK=0"
          ];
          boot = {
            libs = stage1.tinycc.boot.libs.package;
            compiler = stage1.tinycc.boot.compiler.package;
          };
          meta = stage1.tinycc.meta;
        };
      in
        helpers.createTinyccMes {
          pname = "tinycc-mes";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-std=c99"
            "-D HAVE_BITFIELD=1"
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
            "-D HAVE_SETJMP=1"
            "-D CONFIG_TCC_PREDEFS=1"
            "-I ${tccdefs}"
            "-D CONFIG_TCC_SEMLOCK=0"
          ];
          lib.args = [
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
            "-D CONFIG_TCC_PREDEFS=1"
            "-I ${tccdefs}"
            "-D CONFIG_TCC_SEMLOCK=0"
          ];
          boot = tinycc-mes-boot;
          meta = stage1.tinycc.meta;
        };
    in {
      revision = "86f3d8e33105435946383aee52487b5ddf918140";

      libs.package = tinycc-mes.libs;
      compiler.package = tinycc-mes.compiler;

      src = let
        tarball = builtins.fetchurl {
          url = "https://repo.or.cz/tinycc.git/snapshot/${cfg.revision}.tar.gz";
          sha256 = "11idrvbwfgj1d03crv994mpbbbyg63j1k64lw1gjy7mkiifw2xap";
        };

        patched = builders.kaem.build {
          name = "${pname}-src";

          meta = stage1.tinycc.meta;

          script = ''
            ungz --file ${tarball} --output tinycc.tar
            mkdir -p ''${out}
            cd ''${out}
            untar --file ''${NIX_BUILD_TOP}/tinycc.tar

            # Patch
            cd tinycc-${builtins.substring 0 7 cfg.revision}

            # Static link by default
            replace --file libtcc.c --output libtcc.c --match-on "s->ms_extensions = 1;" --replace-with "s->ms_extensions = 1; s->static_link = 1;"
          '';
        };
      in "${patched}/tinycc-${builtins.substring 0 7 cfg.revision}";
    };
  };
}
