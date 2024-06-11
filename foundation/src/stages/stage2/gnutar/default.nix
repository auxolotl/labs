{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.gnutar;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.gnutar = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU implementation of the `tar` archiver";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/tar";
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
        default.value = "tar";
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gnutar.";
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
    aux.foundation.stages.stage2.gnutar = {
      version = "1.35";

      src = builtins.fetchurl {
        url = "${config.aux.mirrors.gnu}/tar/tar-${cfg.version}.tar.gz";
        sha256 = "FNVeMgY+qVJuBX+/Nfyr1TN452l4fv95GcN1WwLStX4=";
      };

      package = builders.bash.build {
        name = "gnutar-static-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gawk.package
          stage1.gzip.package
          stage1.gnutar.package
          stage1.diffutils.package
          stage1.findutils.package
        ];

        script = ''
          # Unpack
          tar xzf ${cfg.src}
          cd tar-${cfg.version}

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
