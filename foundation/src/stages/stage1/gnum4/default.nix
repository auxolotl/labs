{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnum4;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gnum4 = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for gnum4.";
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
        default.value = "GNU M4, a macro processor.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/m4";
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
  };

  config = {
    aux.foundation.stages.stage1.gnum4 = {
      version = "1.4.19";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/m4/m4-${cfg.version}.tar.xz";
        sha256 = "Y67eXG0zttmxNRHNC+LKwEby5w/QoHqpVzoEqCeDr5Y=";
      };

      package = builders.bash.build {
        name = "gnum4-${cfg.version}";
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
          cd m4-${cfg.version}

          # Configure
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            CC=musl-gcc

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install
        '';
      };
    };
  };
}
