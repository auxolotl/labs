{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.findutils;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.findutils = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU Find Utilities, the basic directory searching utilities of the GNU operating system";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/findutils";
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
      description = "The package to use for findutils.";
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
    aux.foundation.stages.stage1.findutils = {
      version = "4.9.0";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/findutils/findutils-${cfg.version}.tar.xz";
        sha256 = "or+4wJ1DZ3DtxZ9Q+kg+eFsWGjt7nVR1c8sIBl/UYv4=";
      };

      package = builders.bash.boot.build {
        name = "findutils-${cfg.version}";

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
          cp ${cfg.src} findutils.tar.xz
          unxz findutils.tar.xz
          tar xf findutils.tar
          rm findutils.tar
          cd findutils-${cfg.version}

          # Patch
          # configure fails to accurately detect PATH_MAX support
          sed -i 's/chdir_long/chdir/' gl/lib/save-cwd.c

          # Configure
          export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
          export AR="tcc -ar"
          export LD=tcc
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host}

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install

        '';
      };
    };
  };
}
