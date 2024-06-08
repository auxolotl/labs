{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.gnused;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.gnused = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU sed, a batch stream editor.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/sed";
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

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "sed";
      };
    };

    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for gnused.";
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
    aux.foundation.stages.stage2.gnused = {
      version = "4.9";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/sed/sed-${cfg.version}.tar.xz";
        sha256 = "biJrcy4c1zlGStaGK9Ghq6QteYKSLaelNRljHSSXUYE=";
      };

      package = builders.bash.build {
        name = "gnused-static-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gnutar.package
          stage1.gawk.package
          stage1.gzip.package
          stage1.diffutils.package
          stage1.findutils.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd sed-${cfg.version}

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
