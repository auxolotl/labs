args @ {
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.tinycc.boot;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;

  pname = "tinycc-boot";

  helpers = lib.fp.withDynamicArgs (import ./helpers.nix) args;
in {
  options.aux.foundation.stages.stage1.tinycc.boot = {
    compiler = {
      package = lib.options.create {
        type = lib.types.package;
        description = "The package to use for the tinycc-boot compiler.";
      };
    };

    libs = {
      package = lib.options.create {
        type = lib.types.package;
        description = "The package to use for the tinycc-boot libs.";
      };
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Tiny C Compiler's bootstrappable fork.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://repo.or.cz/w/tinycc.git";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.lgpl21Only;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["x86_64-linux" "i686-linux"];
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
    aux.foundation.stages.stage1.tinycc.boot = let
      tinycc-boot = let
        tinycc-mes-bootstrappable = helpers.createBoot {
          pname = "tinycc-mes-bootstrappable";
          version = stage1.tinycc.version;
          src = cfg.src;
        };

        tinycc-boot0 = helpers.createTinyccMes {
          pname = "tinycc-boot0";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-D HAVE_LONG_LONG_STUB=1"
            "-D HAVE_SETJMP=1"
          ];
          lib.args = [
            "-D HAVE_LONG_LONG_STUB=1"
          ];
          boot = tinycc-mes-bootstrappable;
          meta = cfg.meta;
        };

        tinycc-boot1 = helpers.createTinyccMes {
          pname = "tinycc-boot1";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-D HAVE_BITFIELD=1"
            "-D HAVE_LONG_LONG=1"
            "-D HAVE_SETJMP=1"
          ];
          lib.args = [
            "-D HAVE_LONG_LONG=1"
          ];
          boot = tinycc-boot0;
          meta = cfg.meta;
        };

        tinycc-boot2 = helpers.createTinyccMes {
          pname = "tinycc-boot2";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-D HAVE_BITFIELD=1"
            "-D HAVE_FLOAT_STUB=1"
            "-D HAVE_LONG_LONG=1"
            "-D HAVE_SETJMP=1"
          ];
          lib.args = [
            "-D HAVE_FLOAT_STUB=1"
            "-D HAVE_LONG_LONG=1"
          ];
          boot = tinycc-boot1;
          meta = cfg.meta;
        };

        tinycc-boot3 = helpers.createTinyccMes {
          pname = "tinycc-boot3";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-D HAVE_BITFIELD=1"
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
            "-D HAVE_SETJMP=1"
          ];
          lib.args = [
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
          ];
          boot = tinycc-boot2;
          meta = cfg.meta;
        };
      in
        helpers.createTinyccMes {
          pname = "tinycc-boot";
          version = stage1.tinycc.version;
          src = cfg.src;
          args = [
            "-D HAVE_BITFIELD=1"
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
            "-D HAVE_SETJMP=1"
          ];
          lib.args = [
            "-D HAVE_FLOAT=1"
            "-D HAVE_LONG_LONG=1"
          ];
          boot = tinycc-boot3;
          meta = cfg.meta;
        };
    in {
      revision = "80114c4da6b17fbaabb399cc29f427e368309bc8";

      libs.package = tinycc-boot.libs;
      compiler.package = tinycc-boot.compiler;

      src = let
        tarball = builtins.fetchurl {
          url = "https://gitlab.com/janneke/tinycc/-/archive/${cfg.revision}/tinycc-${cfg.revision}.tar.gz";
          sha256 = "1a0cw9a62qc76qqn5sjmp3xrbbvsz2dxrw21lrnx9q0s74mwaxbq";
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
            cd tinycc-${cfg.revision}

            # Static link by default
            replace --file libtcc.c --output libtcc.c --match-on "s->ms_extensions = 1;" --replace-with "s->ms_extensions = 1; s->static_link = 1;"
          '';
        };
      in "${patched}/tinycc-${cfg.revision}";
    };
  };
}
