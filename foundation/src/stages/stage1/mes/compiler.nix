{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.mes.compiler;

  system = config.aux.system;
  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.mes.compiler = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Scheme interpreter and C compiler for bootstrapping.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/mes";
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
      description = "The package to use for the mes compiler.";
    };
  };

  config = {
    aux.foundation.stages.stage1.mes.compiler = {
      package = let
        compile = path: let
          file = builtins.baseNameOf path;
          fileWithoutExtension = builtins.replaceStrings [".c"] [""] file;

          cc = builtins.concatStringsSep " " [
            "${stage1.mes.libs.src.bin}/bin/mes-m2"
            "-e"
            "main"
            "${stage1.mes.libs.src.bin}/bin/mescc.scm"
            "--"
            "-D"
            "HAVE_CONFIG_H=1"
            "-I"
            "${stage1.mes.libs.prefix}/include"
            "-I"
            "${stage1.mes.libs.prefix}/include/linux/x86"
          ];
        in
          builders.kaem.build {
            name = fileWithoutExtension;

            script = ''
              mkdir ''${out}
              cd ''${out}
              ${cc} -c ${stage1.mes.libs.prefix}/${path}
            '';
          };

        getSourcePath = suffix: source: "${source}/${source.name}${suffix}";

        sources = import ./sources.nix;

        files =
          lib.strings.concatMapSep
          " "
          (getSourcePath ".o")
          (builtins.map compile sources.x86.linux.mescc.mes);
      in
        builders.kaem.build {
          name = "mes-${stage1.mes.version}";

          meta = cfg.meta;

          script = ''
            mkdir -p ''${out}/bin

            ${stage1.mes.libs.src.bin}/bin/mes-m2 -e main ${stage1.mes.libs.src.bin}/bin/mescc.scm -- \
              -L ${stage1.mes.libs.prefix}/lib \
              -L ${stage1.mes.libs.package}/lib \
              -lc \
              -lmescc \
              -nostdlib \
              -o ''${out}/bin/mes \
              ${stage1.mes.libs.package}/lib/x86-mes/crt1.o \
              ${files}
          '';
        };
    };
  };
}
