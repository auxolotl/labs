{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage2.bash;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage2.bash = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for bash.";
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
        default.value = "GNU Bourne-Again Shell, the de facto standard shell on Linux";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/bash";
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

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "bash";
      };
    };
  };

  config = {
    aux.foundation.stages.stage2.bash = {
      version = "5.2.15";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/bash/bash-${cfg.version}.tar.gz";
        sha256 = "132qng0jy600mv1fs95ylnlisx2wavkkgpb19c6kmz7lnmjhjwhk";
      };

      package = builders.bash.build {
        name = "bash-static-${cfg.version}";

        meta = cfg.meta;

        deps.build.host = [
          stage1.gcc.package
          stage1.musl.package
          stage1.binutils.package
          stage1.gnumake.package
          stage1.gnupatch.package
          stage1.gnused.package
          stage1.gnugrep.package
          stage1.gnutar.package
          stage1.gawk.package
          stage1.gzip.package
          stage1.diffutils.package
          stage1.findutils.package
        ];

        script = ''
          # Unpack
          tar xf ${cfg.src}
          cd bash-${cfg.version}

          # Configure
          bash ./configure \
            --prefix=$out \
            --build=${platform.build} \
            --host=${platform.host} \
            --without-bash-malloc \
            --enable-static-link \
            bash_cv_func_strtoimax=y \
            CC=musl-gcc

          # Build
          make -j $NIX_BUILD_CORES

          # Install
          make -j $NIX_BUILD_CORES install-strip
          rm $out/bin/bashbug

        '';
      };
    };
  };
}
