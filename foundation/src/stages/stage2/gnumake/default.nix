{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.gnumake;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
  stage2 = config.aux.foundation.stages.stage2;
in {
  options.aux.foundation.stages.stage2.gnumake = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "A tool to control the generation of non-source files from sources";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/make";
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
      type = lib.types.package;
      description = "The package to use for gnumake.";
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage2.gnumake = {
      version = "4.4.1";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/make/make-${cfg.version}.tar.gz";
        sha256 = "3Rb7HWe/q3mnL16DkHNcSePo5wtJRaFasfgd23hlj7M=";
      };

      package = let
        patches = [
          # Replaces /bin/sh with sh, see patch file for reasoning
          ./patches/0001-No-impure-bin-sh.patch
          # Purity: don't look for library dependencies (of the form `-lfoo') in /lib
          # and /usr/lib. It's a stupid feature anyway. Likewise, when searching for
          # included Makefiles, don't look in /usr/include and friends.
          ./patches/0002-remove-impure-dirs.patch
        ];
      in
        builders.bash.boot.build {
          name = "gnumake-static-${cfg.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.gcc.package
            stage1.musl.package
            stage1.binutils.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gawk.package
            stage1.diffutils.package
            stage1.findutils.package
            stage1.gnutar.package
            stage1.gzip.package
          ];

          script = ''
            # Unpack
            tar xf ${cfg.src}
            cd make-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}

            # Configure
            bash ./configure \
              --prefix=$out \
              --build=${platform.build} \
              --host=${platform.host} \
              CC=musl-gcc \
              CFLAGS=-static

            # Build
            make -j $NIX_BUILD_CORES

            # Install
            make -j $NIX_BUILD_CORES install

          '';
        };
    };
  };
}
