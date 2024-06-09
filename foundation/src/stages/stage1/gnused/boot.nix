{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnused.boot;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gnused.boot = {
    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for gnused-boot.";
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
    aux.foundation.stages.stage1.gnused.boot = {
      version = "4.0.9";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/sed/sed-${cfg.version}.tar.gz";
        sha256 = "0006gk1dw2582xsvgx6y6rzs9zw8b36rhafjwm288zqqji3qfrf3";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-4.0.9/sed-4.0.9.kaem
        makefile = builtins.fetchurl {
          url = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/sed-4.0.9/mk/main.mk";
          sha256 = "0w1f5ri0g5zla31m6l6xyzbqwdvandqfnzrsw90dd6ak126w3mya";
        };
      in
        builders.bash.boot.build {
          name = "gnused-boot-${cfg.version}";

          meta = stage1.gnused.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.boot.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output sed.tar
            untar --file sed.tar
            rm sed.tar
            cd sed-${cfg.version}

            # Configure
            cp ${makefile} Makefile
            catm config.h

            # Build
            make \
              CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib" \
              LIBC=mes

            # Install
            make install PREFIX=$out
          '';
        };
    };
  };
}
