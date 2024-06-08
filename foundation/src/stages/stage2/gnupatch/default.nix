{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.gnupatch;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.gnupatch = {
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
      type = lib.types.package;
      description = "The package to use for gnupatch.";
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
    aux.foundation.stages.stage2.gnupatch = {
      version = "2.7";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/patch/patch-${cfg.version}.tar.xz";
        sha256 = "XCyR/kFUKWISbwvhUKpPo0lIXPLtwMfqfbwky4FxEa4=";
      };

      package = builders.bash.build {
        name = "gnupatch-static-${cfg.version}";

        meta = cfg.meta;
        src = cfg.src;

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
          cd patch-${cfg.version}

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
