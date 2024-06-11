{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gawk.boot;

  platform = config.aux.platform;
  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gawk.boot = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gnutar-boot.";
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
    aux.foundation.stages.stage1.gawk.boot = {
      version = "3.0.6";

      src = builtins.fetchurl {
        url = "${config.aux.mirrors.gnu}/gawk/gawk-${cfg.version}.tar.gz";
        sha256 = "1z4bibjm7ldvjwq3hmyifyb429rs2d9bdwkvs0r171vv1khpdwmb";
      };

      package = let
        patches = [
          # for reproducibility don't generate date stamp
          ./patches/no-stamp.patch
        ];
      in
        builders.bash.boot.build {
          name = "gawk-boot-${cfg.version}";

          meta = stage1.gawk.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.boot.package
            stage1.gnused.boot.package
            stage1.gnugrep.package
            stage1.gnupatch.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output gawk.tar
            untar --file gawk.tar
            rm gawk.tar
            cd gawk-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np0 -i ${file}") patches}

            # Configure
            export CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib"
            export ac_cv_func_getpgrp_void=yes
            export ac_cv_func_tzset=yes
            bash ./configure \
              --build=${platform.build} \
              --host=${platform.host} \
              --disable-nls \
              --prefix=$out

            # Build
            make gawk

            # Install
            install -D gawk $out/bin/gawk
            ln -s gawk $out/bin/awk
          '';
        };
    };
  };
}
