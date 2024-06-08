{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.ln-boot;

  builders = config.aux.foundation.builders;

  stage0 = config.aux.foundation.stages.stage0;
  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.ln-boot = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "A basic program to create symlinks.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://github.com/auxolotl/labs";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.mit;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for ln-boot.";
    };
  };

  config = {
    aux.foundation.stages.stage1.ln-boot = {
      package = builders.kaem.build {
        name = "ln-boot";

        meta = cfg.meta;

        script = ''
          mkdir -p ''${out}/bin
          ${stage1.mes.compiler.package}/bin/mes --no-auto-compile -e main ${stage1.mes.libs.src.bin}/bin/mescc.scm -- \
            -L ${stage1.mes.libs.package}/lib \
            -lc+tcc \
            -o ''${out}/bin/ln \
            ${./main.c}
        '';
      };
    };
  };
}
