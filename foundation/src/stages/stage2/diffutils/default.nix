{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.diffutils;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.diffutils = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Commands for showing the differences between files (diff, cmp, etc.)";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/diffutils";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl3Only;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for diffutils.";
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
    aux.foundation.stages.stage2.diffutils = {
      version = "3.10";

      src = builtins.fetchurl {
        url = "${config.aux.mirrors.gnu}/diffutils/diffutils-${cfg.version}.tar.xz";
        sha256 = "kOXpPMck5OvhLt6A3xY0Bjx6hVaSaFkZv+YLVWyb0J4=";
      };

      package = builders.bash.build {
        name = "diffutils-static-${cfg.version}";

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
          stage1.xz.package
          stage1.diffutils.package
          stage1.findutils.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd diffutils-${cfg.version}

          # Configure
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            CC=musl-gcc \
            CFLAGS=-static \
            ac_cv_path_PR_PROGRAM=pr

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install

        '';
      };
    };
  };
}
