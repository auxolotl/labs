{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gzip;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gzip = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for gnugrep.";
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
        default.value = "GNU implementation of the Unix grep command";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/grep";
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
    };
  };

  config = {
    aux.foundation.stages.stage1.gzip = {
      version = "1.2.4";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/gzip/gzip-${cfg.version}.tar.gz";
        sha256 = "0ryr5b00qz3xcdcv03qwjdfji8pasp0007ay3ppmk71wl8c1i90w";
      };

      package = let
      in
        builders.bash.boot.build {
          name = "gzip-${cfg.version}";
          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.boot.package
            stage1.gnused.boot.package
            stage1.gnugrep.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output gzip.tar
            untar --file gzip.tar
            rm gzip.tar
            cd gzip-${cfg.version}

            # Configure
            export CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib -Dstrlwr=unused"
            bash ./configure --prefix=$out

            # Build
            make

            # Install
            mkdir $out
            make install
          '';
        };
    };
  };
}
