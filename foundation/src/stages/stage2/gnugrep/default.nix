{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.gnugrep;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.gnugrep = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU implementation of the Unix grep command";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/grep";
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
        default.value = "grep";
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gnugrep.";
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
    aux.foundation.stages.stage2.gnugrep = {
      version = "3.11";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/grep/grep-${cfg.version}.tar.xz";
        sha256 = "HbKu3eidDepCsW2VKPiUyNFdrk4ZC1muzHj1qVEnbqs=";
      };

      package = builders.bash.build {
        name = "gnugrep-static-${cfg.version}";
        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gawk.package
          stage1.diffutils.package
          stage1.findutils.package
          stage1.gnutar.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd grep-${cfg.version}

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
          rm $out/bin/{egrep,fgrep}

        '';
      };
    };
  };
}
