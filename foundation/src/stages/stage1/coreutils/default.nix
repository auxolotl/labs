{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.coreutils;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.coreutils = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for coreutils-boot.";
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
        default.value = ["x86_64-linux" "aarch64-linux" "i686-linux"];
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.coreutils = {
      version = "9.4";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/coreutils/coreutils-${cfg.version}.tar.gz";
        sha256 = "X2ANkJOXOwr+JTk9m8GMRPIjJlf0yg2V6jHHAutmtzk=";
      };

      package = let
        configureFlags = [
          "--prefix=${builtins.placeholder "out"}"
          "--build=${platform.build}"
          "--host=${platform.host}"
          # musl 1.1.x doesn't use 64bit time_t
          "--disable-year2038"
          # libstdbuf.so fails in static builds
          "--enable-no-install-program=stdbuf"
        ];
      in
        builders.bash.boot.build {
          name = "coreutils-${cfg.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.musl.compiler.package
            stage1.gnumake.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gawk.package
            stage1.gnutar.musl.package
            stage1.gzip.package
          ];

          script = ''
            # Unpack
            tar xzf ${cfg.src}
            cd coreutils-${cfg.version}

            # Configure
            export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
            export LD=tcc
            bash ./configure ${builtins.concatStringsSep " " configureFlags}

            # Build
            make -j $NIX_BUILD_CORES AR="tcc -ar" MAKEINFO="true"

            # Install
            make -j $NIX_BUILD_CORES install MAKEINFO="true"
          '';
        };
    };
  };
}
