{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.heirloom;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
  stage2 = config.aux.foundation.stages.stage2;
in {
  includes = [
    ./devtools.nix
  ];

  options.aux.foundation.stages.stage1.heirloom = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for heirloom.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "The Heirloom Toolchest is a collection of standard Unix utilities.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://heirloom.sourceforge.net/tools.html";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.list.of lib.types.attrs.any;
        description = "License for the package.";
        default.value = [
          lib.licenses.zlib
          lib.licenses.caldera
          lib.licenses.bsdOriginalUC
          lib.licenses.cddl
          lib.licenses.bsd3
          lib.licenses.gpl2Plus
          lib.licenses.lgpl21Plus
          lib.licenses.lpl-102
          lib.licenses.info-zip
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
    aux.foundation.stages.stage1.heirloom = {
      version = "070715";

      src = builtins.fetchurl {
        url = "https://downloads.sourceforge.net/heirloom/heirloom/${cfg.version}/heirloom-${cfg.version}.tar.bz2";
        sha256 = "6zP3C8wBmx0OCkHx11UtRcV6FicuThxIY07D5ESWow8=";
      };

      package = let
        patches = [
          # we pre-generate nawk's proctab.c as meslibc is not capable of running maketab
          # during build time (insufficient sscanf support)
          ./patches/proctab.patch

          # disable utilities that don't build successfully
          ./patches/disable-programs.patch

          # "tcc -ar" doesn't support creating empty archives
          ./patches/tcc-empty-ar.patch
          # meslibc doesn't have seperate libm
          ./patches/dont-link-lm.patch
          # meslibc's vprintf doesn't support %ll
          ./patches/vprintf.patch
          # meslibc doesn't support sysconf()
          ./patches/sysconf.patch
          # meslibc doesn't support locale
          ./patches/strcoll.patch
          # meslibc doesn't support termios.h
          ./patches/termios.patch
          # meslibc doesn't support utime.h
          ./patches/utime.patch
          # meslibc doesn't support langinfo.h
          ./patches/langinfo.patch
          # support building with meslibc
          ./patches/meslibc-support.patch
          # remove socket functionality as unsupported by meslibc
          ./patches/cp-no-socket.patch
        ];

        makeFlags = [
          # mk.config build options
          "CC='tcc -B ${stage1.tinycc.mes.libs.package}/lib -include ${./stubs.h} -include ${./musl.h}'"
          "AR='tcc -ar'"
          "RANLIB=true"
          "STRIP=true"
          "SHELL=${stage1.bash.package}/bin/sh"
          "POSIX_SHELL=${stage1.bash.package}/bin/sh"
          "DEFBIN=/bin"
          "SV3BIN=/5bin"
          "S42BIN=/5bin/s42"
          "SUSBIN=/bin"
          "SU3BIN=/5bin/posix2001"
          "UCBBIN=/ucb"
          "CCSBIN=/ccs/bin"
          "DEFLIB=/lib"
          "DEFSBIN=/bin"
          "MANDIR=/share/man"
          "LCURS=" # disable ncurses
          "USE_ZLIB=0" # disable zlib
          "IWCHAR='-I../libwchar'"
          "LWCHAR='-L../libwchar -lwchar'"
        ];
      in
        builders.bash.boot.build {
          name = "heirloom-${cfg.version}";
          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.heirloom.devtools.package
          ];

          script = ''
            # Unpack
            unbz2 --file ${cfg.src} --output heirloom.tar
            untar --file heirloom.tar
            rm heirloom.tar
            cd heirloom-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np0 -i ${file}") patches}
            cp ${./proctab.c} nawk/proctab.c

            # Build
            # These tools are required during later build steps
            export PATH="$PATH:$PWD/ed:$PWD/nawk:$PWD/sed"
            make ${builtins.concatStringsSep " " makeFlags}

            # Install
            make install ROOT=$out ${builtins.concatStringsSep " " makeFlags}
          '';
        };
    };
  };
}
