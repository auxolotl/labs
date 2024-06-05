{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1;

  stage1 = config.aux.foundation.stages.stage1;
in {
  includes = [
    ./nyacc
    ./mes
  ];

  config = {
    exports = {
      packages = {
        stage1-nyacc = stage1.nyacc.package;
        stage1-mes = stage1.mes.compiler.package;
        stage1-mes-libs = stage1.mes.libs.package;
      };

      extras = {
        stage1 = {
          mes = {
            src = stage1.mes.src;
            libs = {
              prefix = stage1.mes.libs.prefix;
            };
          };
        };
      };
    };
  };
}
