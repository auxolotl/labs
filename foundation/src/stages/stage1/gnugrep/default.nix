{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.gnugrep;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.gnugrep = {
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

      mainProgram = lib.options.create {
        type = lib.types.string;
        description = "The main program of the package.";
        default.value = "grep";
      };
    };
  };

  config = {
    aux.foundation.stages.stage1.gnugrep = {
      version = "2.4";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/grep/grep-${cfg.version}.tar.gz";
        sha256 = "05iayw5sfclc476vpviz67hdy03na0pz2kb5csa50232nfx34853";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/grep-2.4
        makefile = builtins.fetchurl {
          url = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/grep-2.4/mk/main.mk";
          sha256 = "08an9ljlqry3p15w28hahm6swnd3jxizsd2188przvvsj093j91k";
        };
      in
        builders.bash.boot.build {
          name = "gnused-boot-${cfg.version}";
          meta = cfg.meta;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output grep.tar
            untar --file grep.tar
            rm grep.tar
            cd grep-${cfg.version}

            # Configure
            cp ${makefile} Makefile

            # Build
            make CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib"

            # Install
            make install PREFIX=$out
          '';
        };
    };
  };
}
