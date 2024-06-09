{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.patchelf;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
  stage2 = config.aux.foundation.stages.stage2;
in {
  options.aux.foundation.stages.stage2.patchelf = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "A small utility to modify the dynamic linker and RPATH of ELF executables.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://github.com/NixOS/patchelf";
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
      description = "The package to use for patchelf.";
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
    aux.foundation.stages.stage2.patchelf = {
      version = "0.18.0";

      src = builtins.fetchurl {
        url = "https://github.com/NixOS/patchelf/releases/download/${cfg.version}/patchelf-${cfg.version}.tar.gz";
        sha256 = "ZN4Q5Ma4uDedt+h/WAMPM26nR8BRXzgRMugQ2/hKhuc=";
      };

      package = builders.bash.build {
        name = "patchelf-static-${cfg.version}";
        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnused.package
          stage2.gnugrep.package
          stage2.gawk.package
          stage1.diffutils.package
          stage1.findutils.package
          stage1.gnutar.package
          stage1.gzip.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd patchelf-${cfg.version}

          # Configure
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            CC=musl-gcc \
            CXXFLAGS=-static

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install-strip

        '';
      };
    };
  };
}
