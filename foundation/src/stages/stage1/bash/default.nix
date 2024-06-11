{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.bash;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./boot.nix
  ];

  options.aux.foundation.stages.stage1.bash = {
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
        default.value = ["i686-linux"];
      };

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "bash";
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for bash.";
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
    aux.foundation.stages.stage1.bash = {
      version = "5.2.15";

      src = builtins.fetchurl {
        url = "${config.aux.mirrors.gnu}/bash/bash-${cfg.version}.tar.gz";
        sha256 = "132qng0jy600mv1fs95ylnlisx2wavkkgpb19c6kmz7lnmjhjwhk";
      };

      package = let
        patches = [
          # flush output for generated code
          ./patches/mksignames-flush.patch
        ];
      in
        builders.bash.boot.build {
          name = "bash-${cfg.version}";

          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.musl.compiler.package
            stage1.coreutils.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.gnused.package
            stage1.gnugrep.package
            stage1.gnutar.musl.package
            stage1.gawk.boot.package
            stage1.gzip.package
            stage1.diffutils.package
          ];

          script = ''
            # Unpack
            tar xzf ${cfg.src}
            cd bash-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np1 -i ${file}") patches}

            # Configure
            export CC="tcc -B ${stage1.tinycc.musl.libs.package}/lib"
            export AR="tcc -ar"
            export LD=tcc
            bash ./configure \
              --prefix=$out \
              --build=${platform.build} \
              --host=${platform.host} \
              --without-bash-malloc

            # Build
            make -j $NIX_BUILD_CORES SHELL=bash

            # Install
            make -j $NIX_BUILD_CORES install
            ln -s bash $out/bin/sh
          '';
        };
    };
  };
}
