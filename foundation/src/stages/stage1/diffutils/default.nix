{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.diffutils;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.diffutils = {
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
    aux.foundation.stages.stage1.diffutils = {
      version = "3.8";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/diffutils/diffutils-${cfg.version}.tar.xz";
        sha256 = "pr3X0bMSZtEcT03mwbdI1GB6sCMa9RiPwlM9CuJDj+w=";
      };

      package = builders.bash.boot.build {
        name = "diffutils-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.tinycc.musl.compiler.package
          stage1.gnumake.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gnutar.musl.package
          stage1.gawk.package
          stage1.xz.package
        ];

        script = ''
          # Unpack
          cp ${cfg.src} diffutils.tar.xz
          unxz diffutils.tar.xz
          tar xf diffutils.tar
          rm diffutils.tar
          cd diffutils-${cfg.version}

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export LD=tcc
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host}

          # Build
          make -j $NIX_BUILD_CORES AR="tcc -ar"

          # Install
          make -j $NIX_BUILD_CORES install
        '';
      };
    };
  };
}
