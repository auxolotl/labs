{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnupatch;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gnupatch = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU Patch, a program to apply differences to files.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/patch";
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
      description = "The package to use for gnupatch.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.derivation;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.gnupatch = {
      version = "2.5.9";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/patch/patch-${cfg.version}.tar.gz";
        sha256 = "12nv7jx3gxfp50y11nxzlnmqqrpicjggw6pcsq0wyavkkm3cddgc";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/patch-2.5.9/mk/main.mk
        cflags = [
          "-I."
          "-DHAVE_DECL_GETENV"
          "-DHAVE_DECL_MALLOC"
          "-DHAVE_DIRENT_H"
          "-DHAVE_LIMITS_H"
          "-DHAVE_GETEUID"
          "-DHAVE_MKTEMP"
          "-DPACKAGE_BUGREPORT="
          "-Ded_PROGRAM=\\\"/nullop\\\""
          "-Dmbstate_t=int" # When HAVE_MBRTOWC is not enabled uses of mbstate_t are always a no-op
          "-DRETSIGTYPE=int"
          "-DHAVE_MKDIR"
          "-DHAVE_RMDIR"
          "-DHAVE_FCNTL_H"
          "-DPACKAGE_NAME=\\\"patch\\\""
          "-DPACKAGE_VERSION=\\\"${cfg.version}\\\""
          "-DHAVE_MALLOC"
          "-DHAVE_REALLOC"
          "-DSTDC_HEADERS"
          "-DHAVE_STRING_H"
          "-DHAVE_STDLIB_H"
        ];

        # Maintenance note: List of sources from Makefile.in
        files = [
          "addext.c"
          "argmatch.c"
          "backupfile.c"
          "basename.c"
          "dirname.c"
          "getopt.c"
          "getopt1.c"
          "inp.c"
          "maketime.c"
          "partime.c"
          "patch.c"
          "pch.c"
          "quote.c"
          "quotearg.c"
          "quotesys.c"
          "util.c"
          "version.c"
          "xmalloc.c"
        ];

        sources =
          files
          ++ [
            # mes-libc doesn't implement `error()`
            "error.c"
          ];

        objects =
          builtins.map
          (
            value:
              builtins.replaceStrings
              [".c"]
              [".o"]
              (builtins.baseNameOf value)
          )
          sources;
      in
        builders.kaem.build {
          name = "gnupatch-${cfg.version}";

          meta = cfg.meta;
          src = cfg.src;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output patch.tar
            untar --file patch.tar
            rm patch.tar
            cd patch-${cfg.version}

            # Configure
            catm config.h

            # Build
            alias CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib ${builtins.concatStringsSep " " cflags}"
            ${lib.strings.concatMapSep "\n" (source: "CC -c ${source}") sources}

            # Link
            CC -o patch ${builtins.concatStringsSep " " objects}

            # Check
            ./patch --version

            # Install
            mkdir -p ''${out}/bin
            cp ./patch ''${out}/bin
            chmod 555 ''${out}/bin/patch
          '';
        };
    };
  };
}
