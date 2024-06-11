{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.coreutils;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.coreutils = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "The GNU Core Utilities.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/coreutils";
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
      description = "The package to use for coreutils.";
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
    aux.foundation.stages.stage2.coreutils = {
      version = "9.4";

      src = builtins.fetchurl {
        url = "${config.aux.mirrors.gnu}/coreutils/coreutils-${cfg.version}.tar.gz";
        sha256 = "X2ANkJOXOwr+JTk9m8GMRPIjJlf0yg2V6jHHAutmtzk=";
      };

      package = let
        configureFlags = [
          "--prefix=${builtins.placeholder "out"}"
          "--build=${platform.build}"
          "--host=${platform.host}"
          # libstdbuf.so fails in static builds
          "--enable-no-install-program=stdbuf"
          "--enable-single-binary=symlinks"
          "CC=musl-gcc"
          "CFLAGS=-static"
        ];
      in
        builders.bash.build {
          name = "coreutils-${cfg.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.gcc.package
            stage1.musl.package
            stage1.binutils.package
            stage1.gnumake.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gawk.package
            stage1.gnutar.musl.package
            stage1.gzip.package
            stage1.findutils.package
            stage1.diffutils.package
          ];

          script = ''
            # Unpack
            tar xzf ${cfg.src}
            cd coreutils-${cfg.version}

            # Configure
            bash ./configure ${builtins.concatStringsSep " " configureFlags}

            # Build
            make -j $NIX_BUILD_CORES

            # Install
            make -j $NIX_BUILD_CORES install
          '';
        };
    };
  };
}
